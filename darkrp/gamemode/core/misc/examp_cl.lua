local defaultTypingOptions = {
    x = sc.w(100),
    y = sc.h(100),
    font = sc.Font("Exo 2 SemiBold:14"),
    color = sc.Color("FFFFFF"),
    delay = 0.03,
    startDelay = 0,
    cursor = true,
    cursorChar = "|",
    cursorSpeed = 5,
    alignX = TEXT_ALIGN_LEFT,
    alignY = TEXT_ALIGN_CENTER,
    sound = false,
    soundPath = "buttons/button15.wav",
    soundVolume = 0.3,
    parent = nil,
    autoStart = true
}

local function Utf8Len(text)
    if utf8 and utf8.len then
        return utf8.len(text) or #text
    end

    return #text
end

local function Utf8Sub(text, from, to)
    if utf8 and utf8.sub then
        return utf8.sub(text, from, to)
    end

    return string.sub(text, from, to)
end

local function MergeTypingOptions(options)
    local result = {}

    for key, value in pairs(defaultTypingOptions) do
        result[key] = value
    end

    for key, value in pairs(options or {}) do
        result[key] = value
    end

    return result
end

local function ParseTypingSegments(data, config)
    local segments = {}

    if isstring(data) then
        segments[1] = { col = config.color, txt = data }
    elseif istable(data) then
        local color = config.color

        for _, value in ipairs(data) do
            if IsColor(value) then
                color = value
            else
                segments[#segments + 1] = { col = color, txt = tostring(value) }
            end
        end
    end

    local totalLen = 0

    for _, segment in ipairs(segments) do
        totalLen = totalLen + Utf8Len(segment.txt)
    end

    return segments, totalLen
end

function CreateTypingText(textData, options)
    local typingText = {
        config = MergeTypingOptions(options),
        segments = {},
        displaySegments = {},
        totalLen = 0,
        currentIndex = 0,
        isTyping = false,
        isComplete = false
    }

    typingText.segments, typingText.totalLen = ParseTypingSegments(textData, typingText.config)

    function typingText:Start()
        if self.isTyping then
            return self
        end

        self.isTyping = true
        self.isComplete = false
        self.currentIndex = 0
        self.displaySegments = {}

        if self.config.startDelay > 0 then
            timer.Simple(self.config.startDelay, function()
                if self.isTyping then
                    self:TypeNextChar()
                end
            end)
        else
            self:TypeNextChar()
        end

        return self
    end

    function typingText:TypeNextChar()
        if not self.isTyping then
            return
        end

        if self.config.parent and not IsValid(self.config.parent) then
            self.isTyping = false
            return
        end

        self.currentIndex = self.currentIndex + 1

        local processed = 0
        local newDisplay = {}

        for _, segment in ipairs(self.segments) do
            local segmentLen = Utf8Len(segment.txt)

            if self.currentIndex > processed + segmentLen then
                newDisplay[#newDisplay + 1] = { col = segment.col, txt = segment.txt }
                processed = processed + segmentLen
            else
                local need = self.currentIndex - processed
                newDisplay[#newDisplay + 1] = { col = segment.col, txt = Utf8Sub(segment.txt, 1, need) }
                break
            end
        end

        self.displaySegments = newDisplay

        if self.config.sound and self.config.soundPath and IsValid(LocalPlayer()) then
            LocalPlayer():EmitSound(self.config.soundPath, 75, 100, self.config.soundVolume)
        end

        if self.currentIndex >= self.totalLen then
            self.isTyping = false
            self.isComplete = true

            if isfunction(self.config.onComplete) then
                self.config.onComplete(self)
            end

            return
        end

        timer.Simple(self.config.delay, function()
            if self.isTyping then
                self:TypeNextChar()
            end
        end)
    end

    function typingText:Skip()
        self.displaySegments = table.Copy(self.segments)
        self.currentIndex = self.totalLen
        self.isTyping = false
        self.isComplete = true

        if isfunction(self.config.onComplete) then
            self.config.onComplete(self)
        end

        return self
    end

    function typingText:Stop()
        self.isTyping = false
        return self
    end

    function typingText:Restart(newData)
        if newData ~= nil then
            self.segments, self.totalLen = ParseTypingSegments(newData, self.config)
        end

        self:Stop()
        self:Start()

        return self
    end

    function typingText:SetText(newData)
        self.segments, self.totalLen = ParseTypingSegments(newData, self.config)

        if not self.isTyping then
            self.displaySegments = {}
            self.currentIndex = 0
            self.isComplete = false
        end

        return self
    end

    function typingText:Draw()
        if #self.displaySegments == 0 then
            return
        end

        surface.SetFont(self.config.font)

        local x = self.config.x

        for index, segment in ipairs(self.displaySegments) do
            local text = segment.txt

            if index == #self.displaySegments and self.config.cursor and self.isTyping then
                if math.sin(CurTime() * self.config.cursorSpeed) > 0 then
                    text = text .. self.config.cursorChar
                end
            end

            draw.SimpleText(text, self.config.font, x, self.config.y, segment.col, self.config.alignX, self.config.alignY)
            x = x + surface.GetTextSize(text)
        end
    end

    if typingText.config.autoStart then
        typingText:Start()
    end

    return typingText
end
