LibPrice = LibPrice or {}

-- Price ---------------------------------------------------------------------
--
-- Just tell me how much it costs.
--
-- Returns the first "suggested or average price in gold" that it can find.
-- Return nil if none found.
-- No crown or voucher prices returned.
--
-- Returns
--      gold price  (number, often a float)
--      source_key  (string "mm", "att", "ttc", others... )
--      field_name  (string "SuggestedPrice", "avgPrice", others... )
--
function LibPrice.ItemLinkToPriceGold(item_link, ...)
    local self   = LibPrice
    local field_names = { "SuggestedPrice", "Avg", "avgPrice", "npcVendor"}

                        -- If source list requested, then search only
                        -- the requested sources. If no source list requested,
                        -- search all sources.
    local requested_source_list = { ... }
    for _,source_key in ipairs(self.SourceList()) do
        if self.Enabled(source_key, requested_source_list) then
            local result = self.Price(source_key, item_link)
            if result then
                for _,field_name in ipairs(field_names) do
                    if result[field_name] then
                        return result[field_name], source_key, field_name
                    end
                end
            end
        end
    end
    return nil
end

-- All the data
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
--  ingredient_list
--      ingr_ct
--      ingr_gold_ea
--      ingr_name
--      ingr_link
--      ingr_gold_sorce_key
--      ingr_gold_field_name
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
--  crowns              lacked when Zig wrote this library's precursor in 2017.
--
-- rolis                Rolis Hlaalu, MasterCraft Mediator, and Faustina Curio,
--  vouchers            Achievement Mediator.
--
-- npc                  Sell to any NPC vendor for gold.
--  npcVendor
--
-- Not getting the price data you expect? Modify your item_link, perhaps
-- simplify some of those unimportant numbers. What does "simplify" and
-- "unimportant" mean here? Varies depending on item. Item links are...
-- enigmatic. See the [UESP page](https://en.uesp.net/wiki/Online:Item_Link)
-- for _some_ explanation.
--
function LibPrice.ItemLinkToPriceData(item_link, ... )
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

