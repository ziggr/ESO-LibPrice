LibPrice = LibPrice or {}

-- Price ---------------------------------------------------------------------
--
-- input:
--  item_link
--  optional: list of sources to return:, any of:
--      "mm"
--      "att"
--      "furc"
--      "ttc"
--
-- Returns:
-- mm                   Master Merchant, by Philgo
--  avgPrice            https://www.esoui.com/downloads/info928-MasterMerchant.html
--  numSales            see MasterMerchant:tooltipStats() for what these
--  numDays             fields mean.
--  numItems
--  craftCost
--
-- att                  Arkadius Trade Tools, by Arkadius, Verbalinkontinenz
--  avgPrice            https://www.esoui.com/downloads/info1752-ArkadiusTradeTools.html
--  numDays             3-day or 90-day range used for this average?
--
-- furc                 Furniture Catalogue, by Manavortex
--  origin              https://www.esoui.com/downloads/info1617-FurnitureCatalogue.html
--  desc
--  currency_type
--  currency_ct
--
-- ttc                  Tamriel Trade Centre, by cyxui
--  Avg                 https://www.esoui.com/downloads/info1245-TamrielTradeCentre.html
--  Max                 see TamrielTradeCentre_PriceInfo:New() and
--  Min                 TamrielTradeCentrePrice:GetPriceInfo() for what these
--  EntryCount          fields mean.
--  AmountCount
--  SuggestedPrice
--
-- crown                Crown store: just a few items that Furniture Catalogue
--                      lacked when Zig wrote this library's precursor in 2017.
--
-- rolis                Rolis Hlaalu, MasterCraft Mediator, and Faustina Curio,
--                      Achievement Mediator.
--
-- npc                  Sell to any NPC vendor for gold.
--
-- Not getting the price data you expect? Modify your item_link, perhaps
-- simplify some of those unimportant numbers. What does "simplify" and
-- "unimportant" mean here? Varies depending on item. Item links are...
-- enigmatic. See the [UESP page](https://en.uesp.net/wiki/Online:Item_Link)
-- for _some_ explanation.
--
function LibPrice.LinkToPrice(item_link, ... )
    local self   = LibPrice
    local result = {}
                        -- If source list requested, then search only
                        -- the requested sources. If no source list requested,
                        -- search all sources.
    local requested_source_list = { ... }
    for _,source_key in ipairs(self.SourceList()) do
        if self.Enabled(source_key, requested_source_list) then
            result[source_key] = self.Price(source_key, item_link)
        end
    end
    return result
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