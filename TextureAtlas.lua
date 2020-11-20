TextureAtlas = {}
TextureAtlas.__index = TextureAtlas

function TextureAtlas.new(texture, metadata)
    local t = {}
    setmetatable(t, TextureAtlas)

    -- open the tileset texture atlas
    t.image = gfx.newImage(texture)

    -- open the tileset data
    local meta = json.opendecode(metadata)
    
    -- add image info to quad data
    local w, h = t.image:getDimensions()

    -- init the list of images from the texture atlas
    t.list = {}

    -- process the meta data
    for i, v in ipairs(meta) do
        -- unpack the quad table into individual vars
        local qx, qy, qw, qh = unpack(v.quad)
        -- create a quad object
        local q = gfx.newQuad(qx, qy, qw, qh, w, h)
        -- create an image entry in the list
        table.insert(t.list, {name=v.name, category=v.category, quad=q})
    end

    return t
end

-- finds a image and returns the quad data, returns nil if not found
function TextureAtlas:getQuadbyName(name)
    for i, v in ipairs(self.list) do
        if v.name == name then
            return v.quad
        end
    end
    return nil
end

-- returns the whole atlas image
function TextureAtlas:getImage()
    return self.image
end

-- returns all image names that belong to the category, or nil if category doesnt exist
function TextureAtlas:findbyCategory(category)
    local names = {}
    for i, v in ipairs(self.list) do
        if v.category == category then
            table.insert(names, v.name)
        end
    end
    if #names == 0 then
        return nil
    else
        return names
    end
end

return TextureAtlas