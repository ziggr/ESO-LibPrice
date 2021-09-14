LibPrice = LibPrice or {}

                        -- How long of a date range to pass to Master Merchant
                        -- and Arkadius Trade Tools.
LibPrice.day_ct_short =  3      -- ATT only
LibPrice.day_ct_long  = 90      -- MM and ATT

                        -- source keys
LibPrice.MM    = "mm"
LibPrice.ATT   = "att"
LibPrice.FURC  = "furc"
LibPrice.TTC   = "ttc"
LibPrice.CROWN = "crown"
LibPrice.ROLIS = "rolis"
LibPrice.NPC   = "npc"


local function Info(msg,...)
    d("|c999999LibPrice: "..string.format(msg,...))
end

local function Error(msg,...)
    d("|cFF6666LibPrice: "..string.format(msg,...))
end

-- Dispatch ------------------------------------------------------------------

function LibPrice.SourceList()
    if not LibPrice.SOURCE_LIST then
        LibPrice.SOURCE_LIST = { LibPrice.MM
                               , LibPrice.ATT
                               , LibPrice.FURC
                               , LibPrice.TTC
                               , LibPrice.CROWN
                               , LibPrice.ROLIS
                               , LibPrice.NPC
                               }
    end
    return LibPrice.SOURCE_LIST
end

function LibPrice.Price(source_key, item_link)
    if not source_key then return nil end
    if not item_link then return nil end
    local self = LibPrice
    if not self.DISPATCH then
        self.DISPATCH = {
          [self.MM   ] = { self.MMPrice    , self.CanMMPrice    }
        , [self.ATT  ] = { self.ATTPrice   , self.CanATTPrice   }
        , [self.FURC ] = { self.FurCPrice  , self.CanFurCPrice  }
        , [self.TTC  ] = { self.TTCPrice   , self.CanTTCPrice   }
        , [self.CROWN] = { self.CrownPrice }
        , [self.ROLIS] = { self.RolisPrice }
        , [self.NPC  ] = { self.NPCPrice   }
        }
    end
    if not (source_key and self.DISPATCH[source_key]) then
        Error("unknown source key:%s", tostring(source_key))
        return nil
    end
    if          self.DISPATCH[source_key][2]
        and not self.DISPATCH[source_key][2]() then
                        -- Requested source not installed/enabled.
        return nil
    end
    local cached = self.GetCachedPrice(source_key, item_link)
    if cached then
        -- Info("cached %s %s", item_link, source_key)
        return cached
    end
    local got = self.DISPATCH[source_key][1](item_link)
    if not got then
        -- Info("%s %s returned nil", item_link, source_key)
        return nil
    end
    self.SetCachedPrice(source_key, item_link, got)
    return got
end

                        -- If the caller requested a specific list of  sources,
                        -- then return true only if key is in that list.
                        --
                        -- If caller did not specify sources, then return true
                        -- for all keys.
function LibPrice.Enabled(key, source_list)
    if #source_list == 0 then return true end
    for _,k in ipairs(source_list) do
        if k == key then return true end
    end
    return false
end

-- Master Merchant ------------------------------------- Philgo, Sharlikran --

function LibPrice.CanMMPrice()
    return MasterMerchant and true
end

function LibPrice.MMPrice(item_link)
    if not (MasterMerchant and MasterMerchant.isInitialized) then return nil end
    if not item_link then return nil end
    local mm = MasterMerchant:itemStats(item_link, false)
    if not (mm and mm.avgPrice and 0 < mm.avgPrice) then
        return nil
    end
    return mm
end

-- Arkadius Trade Tools ----------------------- Arkadius, Verbalinkontinenz --

function LibPrice.CanATTPrice()
    return      ArkadiusTradeTools
            and ArkadiusTradeTools.Modules
            and ArkadiusTradeTools.Modules.Sales
            and ArkadiusTradeTools.Modules.Sales.addMenuItems
            and true
end

function LibPrice.ATTPrice(item_link)
    local self = LibPrice
                        -- ATT initializes its sales data at
                        -- EVENT_PLAYER_ACTIVATED time, which comes after
                        -- EVENT_ADD_ON_LOADED time, when some add-ons
                        -- *cough*WritWorthy*cough* foolishly request price
                        -- data. So check some random internal "addMenuItems"
                        -- that gets set during ATT sales data initialization
                        -- and return nil if ATT is not quite ready.
    if  not(    ArkadiusTradeTools
            and ArkadiusTradeTools.Modules
            and ArkadiusTradeTools.Modules.Sales
            and ArkadiusTradeTools.Modules.Sales.addMenuItems
            )
        then
        return nil
    end

    local day_secs = 24*60*60
    for _,day_ct in ipairs({ self.day_ct_short, self.day_ct_long }) do
        att = ArkadiusTradeTools.Modules.Sales:GetAveragePricePerItem(
                        item_link, GetTimeStamp() - (day_secs * day_ct))
        if att and 0 < att then
            return { avgPrice = att
                   , numDays  = day_ct
                   }
       end
    end
    return nil
end


-- Furniture Catalogue ----------------------------------------- Manavortex --

function LibPrice.CanFurCPrice()
    return FurC and true
end

function LibPrice.FurCPrice(item_link)
    if not item_link then return nil end
    if not FurC then return nil end
    local self = LibPrice

    local item_id       = FurC.GetItemId(item_link)
    local recipe_array  = FurC.Find(item_link)
    if not recipe_array then return nil end
    local origin        = recipe_array.origin
    if not origin then return nil end

    local desc           = FurC.GetItemDescription(item_id, recipe_array)
    local currency_type  = nil
    local currency_ct    = nil
    local currency_notes = nil

    local func_table = {
          [FURC_CRAFTING     ] = self.From_FurC_Crafting           --  3
        , [FURC_VENDOR       ] = self.From_FurC_AchievementVendor  --  6
        , [FURC_PVP          ] = self.From_FurC_PVP                --  7
        , [FURC_CROWN        ] = self.From_FurC_Crown              --  8
        , [FURC_LUXURY       ] = self.From_FurC_Luxury             -- 10
        , [FURC_ROLIS        ] = self.From_FurC_Rolis              -- 12
        , [FURC_DROP         ] = self.From_FurC_Misc               -- 14
        , [FURC_JUSTICE      ] = self.From_FurC_Misc               -- 15

        -- These tables never have per-item price data.
        , [FURC_RUMOUR       ] = self.From_FurC_NoPrice            --  9
        , [FURC_FESTIVAL_DROP] = self.From_FurC_NoPrice            -- 18
        }
    local func = func_table[origin] or self.From_FurC_Misc
    if func then  currency_type, currency_ct, currency_notes, ingredient_list
            = func(item_link, recipe_array)
    end

    local o = { origin          = origin
              , desc            = desc
              , currency_type   = currency_type
              , currency_ct     = currency_ct
              , notes           = currency_notes
              , ingredient_list = ingredient_list
              }
    return o
end


LibPrice.CURRENCY_TYPE_GOLD            = "gold"
LibPrice.CURRENCY_TYPE_WRIT_VOUCHERS   = "vouchers"
LibPrice.CURRENCY_TYPE_ALLIANCE_POINTS = "ap"
LibPrice.CURRENCY_TYPE_CROWNS          = "crowns"


-- Looking for FURC_XXX recipe_array.version values?
-- -- versioning
-- FURC_HOMESTEAD            = 2
-- FURC_MORROWIND            = 3
-- FURC_REACH                = 4
-- FURC_CLOCKWORK            = 5
-- FURC_DRAGONS              = 6
-- FURC_ALTMER               = 7
-- FURC_WEREWOLF             = 8
-- FURC_SLAVES               = 9

-- Dig deep into the data model of Furniture Catalogue,
-- because there's no public API for this (Furniture Catalogue
-- was never intended to become a public database).
--
function LibPrice.From_FurC_Crafting(item_link, recipe_array)
    local self = LibPrice
    if not recipe_array.blueprint then return nil, nil end
    local total_ingr_gold = 0
    local ingr_list       = {}
    local notes           = "Crafting cost"
    local blueprint_link  = FurC.GetItemLink(recipe_array.blueprint)
    local ingredient_ct   = GetItemLinkRecipeNumIngredients(blueprint_link)
    for ingr_i = 1, ingredient_ct do
        local _, _, ct    = GetItemLinkRecipeIngredientInfo(blueprint_link, ingr_i )
        local ingr_link   = GetItemLinkRecipeIngredientItemLink(blueprint_link, ingr_i )
        local ingr_name   = GetItemLinkName(ingr_link)
                        -- Recurse into each ingredient to get its gold cost.
                        -- If calling code wants more details about each
                        -- ingredient's cost, call ItemLinkToPriceData() on
                        -- each ingredient. I'm not going to do here.
        local gold, source_key, field_name = self.ItemLinkToPriceGold(ingr_link)
        local ingr_row = { ingr_ct              = ct
                         , ingr_name            = ingr_name
                         , ingr_link            = ingr_link
                         , ingr_gold_ea         = gold
                         , ingr_gold_source_key = source_key
                         , ingr_gold_field_name = field_name
                         }
        table.insert(ingr_list, ingr_row)
        if gold then
            total_ingr_gold = total_ingr_gold + ct * gold
        else
            notes = "Partial crafting cost, missing some ingredient costs."
        end
    end
    return self.CURRENCY_TYPE_GOLD, total_ingr_gold, notes, ingr_list
end

function LibPrice.From_FurC_Rolis(item_link, recipe_array)
    local self = LibPrice
    local item_id       = FurC.GetItemId(item_link)
    local seller_list   = { FurC.Rolis, FurC.Faustina }
    local seller_names  = { "Rolis", "Faustina" }
    local version_data  = nil
    for i, seller in ipairs(seller_list) do
        version_data = seller[recipe_array.version]
        if version_data and version_data[item_id] then break end
    end
    if not (version_data and version_data[item_id]) then return nil end
    local ct = version_data[item_id]
    return self.CURRENCY_TYPE_WRIT_VOUCHERS, ct, seller_names[i]
end

function LibPrice.From_FurC_Luxury(item_link, recipe_array)
    local self = LibPrice
    local version_data = FurC.LuxuryFurnisher[recipe_array.version]
    if not version_data then return nil end
    local item_id   = FurC.GetItemId(item_link)
    local item_data = version_data[item_id]
    if not item_data then return nil end
    return self.CURRENCY_TYPE_GOLD, item_data.itemPrice, "luxury vendor"
end

function LibPrice.From_FurC_AchievementVendor(item_link, recipe_array)
    local self = LibPrice
    local item_id      = FurC.GetItemId(item_link)
    local version_data = FurC.AchievementVendors[recipe_array.version]
    if not version_data then return nil end
    local entry = nil
    local notes = nil
    for location_name, zone_data in pairs(version_data) do
        for vendor_name, vendor_data in pairs(zone_data) do
            entry = vendor_data[item_id]
            if entry then
                notes = vendor_name .. " in " .. location_name
                return self.CURRENCY_TYPE_GOLD, entry.itemPrice, notes
            end
        end
    end
    return nil
end

function LibPrice.From_FurC_Generic(item_link, recipe_array, currency_type)
    local self = LibPrice
    local item_id      = FurC.GetItemId(item_link)
    local version_data = FurC.MiscItemSources[recipe_array.version]
    if not version_data then return nil, nil, nil end
    local origin_data  = version_data[recipe_array.origin]
    if not origin_data then return nil, nil, nil end
    local entry = origin_data[item_id]
    if type(entry) == "number" then
        return currency_type, entry, nil
    elseif type(entry) == "string" then
        local n = string.match(entry, "%d+")
        if n and tonumber(n) then
            return currency_type, tonumber(n), nil
        end
    elseif type(entry) == "table" then
        if entry.itemPrice then
            return currency_type, entry.itemPrice, nil
        end
    end
    return nil
end

function LibPrice.From_FurC_Crown(item_link, recipe_array)
    local self = LibPrice
    return self.From_FurC_Generic(item_link, recipe_array, self.CURRENCY_TYPE_CROWNS)
end

function LibPrice.From_FurC_Misc(item_link, recipe_array)
    local self = LibPrice
    return self.From_FurC_Generic(item_link, recipe_array, self.CURRENCY_TYPE_GOLD)
end

-- Rumor table and others lack any per-item details.
-- No point in wasting time in the Misc tables.
function LibPrice.From_FurC_NoPrice(item_link, recipe_array)
    return nil
end

function LibPrice.From_FurC_PVP(item_link, recipe_array, currency_type)
    local self = LibPrice
    local item_id      = FurC.GetItemId(item_link)
    local version_data = FurC.PVP[recipe_array.version]
    if not version_data then return nil, nil, nil end
    local entry = nil
    for vendor_name, vendor_data in pairs(version_data) do
        for location_name, location_data in pairs(vendor_data) do
            entry = location_data[item_id]
            if entry then break end
        end
    end
    if not entry then return nil end

    local notes = (vendor_name or "?") .. " in " .. (location_name or "?")
    return self.CURRENCY_TYPE_ALLIANCE_POINTS, entry.itemPrice, notes
end


-- Tamriel Trade Centre --------------------------------------------- cyxui --

function LibPrice.CanTTCPrice()
    return TamrielTradeCentrePrice and true
end

function LibPrice.TTCPrice(item_link)
    if not TamrielTradeCentrePrice then return nil end
    return TamrielTradeCentrePrice:GetPriceInfo(item_link)
end


-- Crown Store ------------------------------------------------------ ziggr --
--
-- Furniture Catalogue catches MOST crown store items. Here's a few more
-- that FurC did not list (at least way back in 2017 when Zig originally
-- wrote the precursor to this library.)

function LibPrice.CrownPrice(item_link)
    if not item_link then return nil end
    local self = LibPrice
    if not self.CASH then
        self.CASH = {
          ["The Apprentice"                         ] = { crowns   = 4000 }
        , ["The Atronach"                           ] = { crowns   = 4000 }
        , ["The Tower"                              ] = { crowns   = 4000 }
        , ["The Thief"                              ] = { crowns   = 4000 }
        , ["The Serpent"                            ] = { crowns   = 4000 }
        , ["The Ritual"                             ] = { crowns   = 4000 }
        , ["The Mage"                               ] = { crowns   = 4000 }
        , ["The Lady"                               ] = { crowns   = 4000 }
        , ["The Lord"                               ] = { crowns   = 4000 }
        , ["The Warrior"                            ] = { crowns   = 4000 }
        , ["The Lover"                              ] = { crowns   = 4000 }
        , ["The Steed"                              ] = { crowns   = 4000 }
        , ["The Shadow"                             ] = { crowns   = 4000 }
           --torage Coffer, Fortified"              ] = { crowns =  100 } one of these was free for reaching level 1
        , ["Storage Coffer, Secure"                 ] = { crowns =  100 }
        , ["Storage Coffer, Sturdy"                 ] = { crowns =  100 }
        , ["Storage Coffer, Oaken"                  ] = { crowns =  100 }
        , ["Storage Chest, Fortified"               ] = { crowns =  200 }
        , ["Storage Chest, Oaken"                   ] = { crowns =  200 }
        , ["Storage Chest, Secure"                  ] = { crowns =  200 }
        , ["Storage Chest, Sturdy"                  ] = { crowns =  200 }

        , ["Nuzhimeh the Merchant"                  ] = { crowns = 5000 }
        --["Pirharri the Smuggler"                  ] = ) -- Free for completing Thieves Guild quest lin
        , ["Tythis Andromo, the Banker"             ] = { crowns = 5000 }

        , ["Music Box, Blood and Glory"             ] = { crowns =  800 }

        , ["Imperial Pillar, Chipped"               ] = { crowns =  410 }
        , ["Imperial Pillar, Straight"              ] = { crowns =  410 }

        }
    end
                        -- EN English only for now, need to get proper links
                        -- and fix this.
    local name = GetItemLinkName(item_link)
    return self.CASH[name]
end

LibPrice.LINK_ATTUNABLE_BS = "|H1:item:119594:364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:10000:0|h|h"
LibPrice.LINK_ATTUNABLE_CL = "|H1:item:119821:364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:10000:0|h|h"
LibPrice.LINK_ATTUNABLE_WW = "|H1:item:119822:364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:10000:0|h|h"
LibPrice.LINK_ATTUNABLE_JW = "|H1:item:137947:364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:10000:0|h|h"


-- Rolis Hlaalu, Master Crafter Merchant ---------------------------- ziggr --

function LibPrice.RolisPrice(item_link)
    if not item_link then return nil end
    local self = LibPrice
    if not self.ROLIS_PRICE then
        self.ROLIS_PRICE = {
          [self.LINK_ATTUNABLE_BS] = { vouchers =  250 }
        , [self.LINK_ATTUNABLE_CL] = { vouchers =  250 }
        , [self.LINK_ATTUNABLE_WW] = { vouchers =  250 }
        , [self.LINK_ATTUNABLE_JW] = { vouchers =  250 }

        , ["Transmute Station"   ] = { vouchers = 1250 }
        }
    end
    local l = self.Unattune(item_link)
    local result = self.ROLIS_PRICE[l.item_link]

                        -- Fallback to EN English name for transmute
    if not result then
        local item_name = GetItemLinkName(item_link)
        result = self.ROLIS_PRICE[item_name]
    end
    return result
end

function LibPrice.Unattune(item_link)
    local self = LibPrice
                        -- Remove the "attuning" that makes these
                        -- crafting stations unique, preventing FurC
                        -- and MM from coming up with prices, AND
                        -- preventing us from combining them into a single
                        -- stack of count 44 instead of 44 unique items.
                        --
                        -- Note trailing space after each station name!
                        -- Required to avoid false match on non-attunable
                        -- stations.

                        -- EN English only for now. Fix later.
    local item_name = GetItemLinkName(item_link)

    if string.find(item_name, "Blacksmithing Station ") then
        return {
              item_name = "Attunable Blacksmithing Station"
            , item_link = self.LINK_ATTUNABLE_BS
            , furniture_data_id = 4050
            }
    elseif string.find(item_name, "Clothing Station ") then
        return {
              item_name = "Attunable Clothier Station"
            , item_link = self.LINK_ATTUNABLE_CL
            , furniture_data_id = 4051
            }
    elseif string.find(item_name, "Woodworking Station ") then
        return {
              item_name = "Attunable Woodworking Station"
            , item_link = self.LINK_ATTUNABLE_WW
            , furniture_data_id = 4052
            }
    elseif string.find(item_name, "Jewelry Crafting Station ") then
        return {
              item_name = "Attunable Jewelry Crafting Station"
            , item_link  = self.LINK_ATTUNABLE_JW
            , furniture_data_id = 4051
            }
    end
                        -- Nothing to unattune. Return original, unchanged.
    return { item_name = item_name
           , item_link = item_link
           }
end


-- NPC Vendor ----------------------------------------------------------------

function LibPrice.NPCPrice(item_link)
    local o = { GetItemLinkInfo(item_link) }
    if not (o and o[2] and 0 < o[2]) then return nil end
    return { npcVendor = o[2] }
end


-- Cache ---------------------------------------------------------------------
--
-- Calculating an "average price" from MM and ATT is an O(n) scan through
-- sales records. Expensive. Cache results for a few minutes to avoid crushing
-- the CPU with wasteful re-calculation.

LibPrice.cache              = nil
LibPrice.cache_reset_ts     = nil
LibPrice.CACHE_DUR_SECONDS  = 5 * 60

                        -- Allow cached data to expire after a few minutes.
function LibPrice.ResetCacheIfNecessary()
    local self = LibPrice
    local now_ts        = GetTimeStamp()
    self.cache_reset_ts = self.cache_reset_ts or now
    local prev_reset_ts = self.cache_reset_ts
    local ago_secs      = GetDiffBetweenTimeStamps(now_ts, prev_reset_ts)
    if self.CACHE_DUR_SECONDS < ago_secs then
        -- d("|cDD6666cache reset, ago_secs:"..tostring(ago_secs))
        self.cache = {}
        self.cache_reset_ts = now_ts
    else
        -- d("|c666666cache retained, ago_secs:"..tostring(ago_secs))
    end
end

function LibPrice.GetCachedPrice(source_key, item_link)
    LibPrice.ResetCacheIfNecessary()
    if not (  LibPrice.cache
            and LibPrice.cache[source_key]) then
        -- d("|cDDD666cache miss:"..item_link)
        return nil
    end
    -- d("|c66DD66cache hit:"..item_link)
    return LibPrice.cache[source_key][item_link]
end

function LibPrice.SetCachedPrice(source_key, item_link, value)
    LibPrice.cache                        = LibPrice.cache             or {}
    LibPrice.cache[source_key]            = LibPrice.cache[source_key] or {}
    LibPrice.cache[source_key][item_link] = value
end

