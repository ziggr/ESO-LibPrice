LibPrice_Example = LibPrice_Example or {}

SLASH_COMMANDS["/example"] = function() LibPrice_Example.SlashCommand() end

local EXAMPLE_ITEMS = {
                    -- essence of health
      "|H1:item:54339:308:50:0:0:0:0:0:0:0:0:0:0:0:0:36:1:0:0:0:65536|h|h"
                    -- Crown Tri-Restoration Potion
    , "|H1:item:64710:123:1:0:0:0:0:0:0:0:0:0:0:0:1:36:0:1:0:0:0|h|h"
                    -- Recipe: Raven Rock Baked Ash Yams
    , "|H0:item:56970:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                    -- Necklace of Willpower
    , "|H1:item:69278:363:50:0:0:0:0:0:0:0:0:0:0:0:257:24:0:1:0:0:0|h|h"
                    -- Trees, Paired Evergreens
    , "|H1:item:120550:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                    -- Varla Stone
    , "|H1:item:134465:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                    -- Tempering Alloy
    , "|H1:item:54173:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                    -- Platinum Necklace, intricate
    , "|H0:item:138797:307:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                    -- Jewelry station Naga Shaman
    , "|H1:item:145501:124:1:0:0:0:0:0:0:0:0:0:0:0:1:0:0:1:0:0:0|h|h"
                    -- Mundus Stone: The Warrior
    , "|H1:item:125453:6:1:0:0:0:0:0:0:0:0:0:0:0:65:0:0:1:0:0:0|h|h"
                    -- Transmute Station
    , "|H1:item:133576:6:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
    }

function LibPrice_Example.SlashCommand()
    local self = LibPrice_Example

    for _,item_link in ipairs(EXAMPLE_ITEMS) do
                        -- Just tell me how much this thing costs.
        local gold   = LibPrice.ItemLinkToPriceGold(item_link)

                        -- Okay, I changed my mind. Tell me a little more:
                        -- where'd you get  this price from?
                        -- (additional return values from same API)
        gold, source_key, field_name
                     = LibPrice.ItemLinkToPriceGold(item_link)
        local header = self.FormatHeader(item_link, gold, source_key, field_name)
        d(header)

                        -- Give me all the data you can find, I'll figure out
                        -- what to do with it later.
        local result = LibPrice.ItemLinkToPriceData(item_link)
        LibPrice_Example.DumpTable(result)
    end
end

function LibPrice_Example.FormatHeader(item_link, gold, source_key, field_name)
    local grey     = "|c999999"
    local white    = "|cFFFFFF"

    if not gold then
        local msg = string.format(
             "%s  "..grey.."price:unknown"
            , item_link )
        return msg
    end

    local gold_str = LibPrice_Example.GoldString(gold)
    local msg = string.format(
         "%s  "..grey.."price:"..white.."%s "..grey.." from %s.%s"
        , item_link
        , gold_str
        , source_key
        , field_name
        )
    return msg
end

function LibPrice_Example.GoldString(n)
    if not n then return tostring(n) end
    return ZO_LocalizeDecimalNumber(n)
            .." |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
end

                        -- A recursive table dumper that does a marginally better
                        -- job of indenting than d()
function LibPrice_Example.DumpTable(t, indent_ct)
    local grey  = "|c999999"
    local white = "|cFFFFFF"
    local red   = "|cFF6666"
    if not t then
        d(red..tostring(t))
        return
    end
    indent_ct = indent_ct or 1
    local indent = string.format(".%"..(indent_ct*4).."."..(indent_ct*4).."s","")
                        -- Infinite recursion blocker
    if 4 < indent_ct then
        d(grey..indent.."...")
        return
    end
                        -- Can we squish down to single line?
    local has_sub_tables = false
    for k,v in pairs(t) do
        if type(v) == "table"
            and k ~= "points"   -- Omit MM's huge "points" history table.
            then
            has_sub_tables = true
            break
        end
    end
    if not has_sub_tables then
        local line = ""
        local sorted = LibPrice_Example.SortedKeys(t)
        for _,k in ipairs(sorted) do
            local v = t[k]
            if type(v) == "table" then
                        -- omit hex addr from tables that we choose not to
                        -- recurse into.
                v="table"
            end
            line = line .. string.format(grey.."%s:"..white.."%s  ",tostring(k),tostring(v))
        end
        d(indent..line)
    else
                        -- Gonna have to recurse, so print each key/value pair
                        -- on its own line.
        local sorted = LibPrice_Example.SortedKeys(t)
        for _,k in ipairs(sorted) do
            local v = t[k]
            local vv = tostring(v)
            if type(v) == "table" then vv = "table" end -- Omit useless hex addresses.
            d(string.format(grey..indent.."%-4s: "..white.."%s", tostring(k), vv))
            if type(v) == "table"
                and k ~= "points"       -- Omit MM's huge "points" history table.
                then
                LibPrice_Example.DumpTable(v,1+indent_ct)
            end
        end
    end
end
                        -- To provide more stable output.
function LibPrice_Example.SortedKeys(t)
    local r = {}
    for k,_ in pairs(t) do
        table.insert(r,k)
    end
    table.sort(r)
    return r
end
