# LibPrice

A library for gathering an item's cost from various add-ons:

- [Master Merchant](https://www.esoui.com/downloads/info928-MasterMerchant.html), by Philgo68
- [Arkadius' Trade Tools](https://www.esoui.com/downloads/info1752-ArkadiusTradeTools.html), by Arkadius, Verbalinkontinenz
- [Tamriel Trade Centre](https://www.esoui.com/downloads/info1245-TamrielTradeCentre.html), by cyxui
- [Furniture Catalogue](https://www.esoui.com/downloads/info1617-FurnitureCatalogue.html), by manavortex

As well as some hard-coded data from

- The Crown Store
- Rolis Hlaalu, the Mastercraft Mediator
- Faustina Curio, the Achievement Mediator

## Example Code

```lua
function LibPrice_Example.SlashCommand()
    local ITEMS = {
                        -- essence of health
          "|H1:item:54339:308:50:0:0:0:0:0:0:0:0:0:0:0:0:36:1:0:0:0:65536|h|h"
                        -- Crown Tri-Restoration Potion
        , "|H1:item:64710:123:1:0:0:0:0:0:0:0:0:0:0:0:1:36:0:1:0:0:0|h|h"
                        -- Necklace of Willpower
        , "|H1:item:69278:363:50:0:0:0:0:0:0:0:0:0:0:0:257:24:0:1:0:0:0|h|h"
                        -- Trees, Paired Evergreens
        , "|H1:item:120550:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                        -- Varla Stone
        , "|H1:item:134465:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                        -- Recipe: Raven Rock Baked Ash Yams
        , "|H0:item:56970:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                        -- Platinum Necklace, intricate
        , "|H0:item:138797:307:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
                        -- Jewelry station Naga Shaman
        , "|H1:item:145501:124:1:0:0:0:0:0:0:0:0:0:0:0:1:0:0:1:0:0:0|h|h"
                        -- Mundus Stone: The Warrior
        , "|H1:item:125453:6:1:0:0:0:0:0:0:0:0:0:0:0:65:0:0:1:0:0:0|h|h"
                        -- Transmute Station
        , "|H1:item:133576:6:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
        }
    for _,item_link in ipairs(ITEMS) do
        local result = LibPrice.LinkToPrice(item_link)
        d(item_link)
        LibPrice_Example.DumpTable(result)
    end
end
```
![example](doc/example.jpg)



