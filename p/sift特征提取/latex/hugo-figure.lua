-- hugo-figure.lua
-- Pandoc Lua filter: convert LaTeX figures to Hugo {{< figure >}} shortcodes
-- Compatible with Pandoc 3.x (Caption object)

local function blocks_to_text(blocks)
    local parts = {}
    for _, block in ipairs(blocks) do
        if block.t == "Para" or block.t == "Plain" then
            for _, inline in ipairs(block.content) do
                if inline.t == "Str" then
                    table.insert(parts, inline.text)
                elseif inline.t == "Space" then
                    table.insert(parts, " ")
                elseif inline.t == "Math" then
                    table.insert(parts, inline.text)
                elseif inline.t == "SoftBreak" or inline.t == "LineBreak" then
                    table.insert(parts, " ")
                end
            end
        end
    end
    return table.concat(parts)
end

function Figure(fig)
    -- Pandoc 3.x: fig.caption is a Caption object with .long (blocks) and .short
    local main_caption = ""
    if fig.caption and fig.caption.long then
        main_caption = blocks_to_text(fig.caption.long)
    end

    local images = {}
    local function collect_images(blocks)
        for _, block in ipairs(blocks) do
            if block.t == "Para" or block.t == "Plain" then
                for _, inline in ipairs(block.content) do
                    if inline.t == "Image" then
                        local alt_text = ""
                        for _, alt_inline in ipairs(inline.caption) do
                            if alt_inline.t == "Str" then
                                alt_text = alt_text .. alt_inline.text
                            elseif alt_inline.t == "Space" then
                                alt_text = alt_text .. " "
                            end
                        end
                        table.insert(images, {
                            src = inline.src,
                            alt = alt_text
                        })
                    end
                end
            end
        end
    end
    collect_images(fig.content)

    if #images == 0 then
        return fig
    end

    local result = {}
    for _, img in ipairs(images) do
        local src = img.src:gsub("^%./", ""):gsub("^figures/", "figures/")
        local title
        if #images == 1 then
            title = main_caption
        else
            title = (img.alt ~= "") and img.alt or main_caption
        end
        local safe_title = title:gsub('"', '\\"')
        table.insert(result, pandoc.RawBlock("markdown", '{{< figure src="./' .. src .. '" title="' .. safe_title .. '" >}}'))
    end
    return result
end
