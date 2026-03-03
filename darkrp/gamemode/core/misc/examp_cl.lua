function CreateTypingText(textData, options)
    local config = {
        x = sc.w(100),
        y = sc.h(100),
        font = sc.Font("Exo 2 SemiBold:14"),
        color = sc.Color('FFFFFF'),
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

    if options then 
        for k, v in pairs(options) do 
            config[k] = v 
        end 
    end

    local function parseTextData(data)
        local segments = {}
        if isstring(data) then
            table.insert(segments, {col = config.color, txt = data})
        elseif istable(data) then
            local lastCol = config.color
            for _, v in ipairs(data) do
                if IsColor(v) then 
                    lastCol = v 
                else 
                    table.insert(segments, {col = lastCol, txt = tostring(v)}) 
                end
            end
        end
        local len = 0
        for _, seg in ipairs(segments) do len = len + utf8.len(seg.txt) end
        return segments, len
    end

    local initialSegments, initialLen = parseTextData(textData)

    local typingText = {
        segments = initialSegments,
        displaySegments = {},
        totalLen = initialLen,
        currentIndex = 0,
        isTyping = false,
        isComplete = false,
        config = config,

        Start = function(self)
            if self.isTyping then return self end
            self.isTyping, self.isComplete, self.currentIndex = true, false, 0
            self.displaySegments = {}
            
            if self.config.startDelay > 0 then
                timer.Simple(self.config.startDelay, function()
                    if self and self.isTyping then self:TypeNextChar() end
                end)
            else
                self:TypeNextChar()
            end
            return self
        end,

        TypeNextChar = function(self)
            if not self or not self.isTyping then return end
            if self.config.parent and not IsValid(self.config.parent) then return end

            self.currentIndex = self.currentIndex + 1
            
            local processed = 0
            local newDisplay = {}
            for _, seg in ipairs(self.segments) do
                local segLen = utf8.len(seg.txt)
                if self.currentIndex > processed + segLen then
                    table.insert(newDisplay, {col = seg.col, txt = seg.txt})
                    processed = processed + segLen
                else
                    local remaining = self.currentIndex - processed
                    table.insert(newDisplay, {col = seg.col, txt = utf8.sub(seg.txt, 1, remaining)})
                    processed = processed + remaining
                    break
                end
            end
            self.displaySegments = newDisplay

            if self.config.sound and self.config.soundPath then
                LocalPlayer():EmitSound(self.config.soundPath, 75, 100, self.config.soundVolume)
            end

            if self.currentIndex >= self.totalLen then
                self.isTyping, self.isComplete = false, true
                if self.config.onComplete then self.config.onComplete(self) end
                return
            end

            timer.Simple(self.config.delay, function()
                if self and self.isTyping then self:TypeNextChar() end
            end)
        end,

        Skip = function(self)
            self.displaySegments = table.Copy(self.segments)
            self.currentIndex = self.totalLen
            self.isTyping, self.isComplete = false, true
            if self.config.onComplete then self.config.onComplete(self) end
            return self
        end,

        Stop = function(self)
            self.isTyping = false
            return self
        end,

        Restart = function(self, newData)
            if newData then
                self.segments, self.totalLen = parseTextData(newData)
            end
            self:Stop()
            self:Start()
            return self
        end,

        SetText = function(self, newData)
            self.segments, self.totalLen = parseTextData(newData)
            if not self.isTyping then
                self.displaySegments = {}
                self.currentIndex = 0
                self.isComplete = false
            end
            return self
        end,

        Draw = function(self)
            if #self.displaySegments == 0 then return end
            surface.SetFont(self.config.font)
            
            local curX = self.config.x
            for i, seg in ipairs(self.displaySegments) do
                local txt = seg.txt
                if i == #self.displaySegments and self.config.cursor and self.isTyping then
                    if math.sin(CurTime() * self.config.cursorSpeed) > 0 then
                        txt = txt .. self.config.cursorChar
                    end
                end

                draw.SimpleText(txt, self.config.font, curX, self.config.y, seg.col, self.config.alignX, self.config.alignY)
                local w, _ = surface.GetTextSize(txt)
                curX = curX + w
            end
        end,

        IsValid = function(self) return true end
    }

    if config.autoStart then typingText:Start() end
    return typingText
end