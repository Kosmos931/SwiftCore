-- что то сделаю с этим не забыть бы
// --
// -- Функция для создания плавно появляющегося текста
// function CreateTypingText(text, options)
//     -- Параметры по умолчанию
//     local config = {
//         x = 100,
//         y = 100,
//         font = "DermaDefault",
//         color = Color(255, 255, 255),
//         delay = 0.03, -- задержка между символами
//         startDelay = 0, -- задержка перед началом
//         cursor = true, -- показывать мигающий курсор
//         cursorChar = "|",
//         cursorSpeed = 5, -- скорость мигания курсора
//         sound = false, -- звук печатания
//         soundPath = "buttons/button15.wav",
//         soundVolume = 0.3,
//         align = TEXT_ALIGN_LEFT,
//         onStart = nil, -- функция при старте
//         onComplete = nil, -- функция при завершении
//         onChar = nil, -- функция при добавлении каждого символа
//         parent = nil, -- родительская панель (для vgui)
//         shadow = false, -- тень текста
//         shadowColor = Color(0, 0, 0, 150),
//         shadowOffset = 1,
//         outline = false, -- обводка текста
//         outlineColor = Color(0, 0, 0),
//         outlineWidth = 2
//     }
    
//     -- Применяем пользовательские настройки
//     if options then
//         for k, v in pairs(options) do
//             config[k] = v
//         end
//     end
    
//     -- Создаем объект текста
//     local typingText = {
//         fullText = text,
//         displayText = "",
//         currentIndex = 1,
//         isTyping = false,
//         isComplete = false,
//         startTime = CurTime(),
//         config = config,
        
//         -- Методы
//         Start = function(self)
//             if self.isTyping then return self end
            
//             self.isTyping = true
//             self.isComplete = false
//             self.displayText = ""
//             self.currentIndex = 1
//             self.startTime = CurTime() + self.config.startDelay
            
//             -- Вызываем callback при старте
//             if self.config.onStart then
//                 self.config.onStart(self)
//             end
            
//             -- Запускаем анимацию с учетом начальной задержки
//             if self.config.startDelay > 0 then
//                 timer.Simple(self.config.startDelay, function()
//                     if IsValid(self) then
//                         self:TypeNextChar()
//                     end
//                 end)
//             else
//                 self:TypeNextChar()
//             end
            
//             return self
//         end,
        
//         TypeNextChar = function(self)
//             if not self.isTyping or self.currentIndex > #self.fullText then
//                 self.isTyping = false
//                 self.isComplete = true
                
//                 -- Вызываем callback при завершении
//                 if self.config.onComplete then
//                     self.config.onComplete(self)
//                 end
//                 return
//             end
            
//             -- Добавляем следующий символ
//             local char = string.sub(self.fullText, self.currentIndex, self.currentIndex)
//             self.displayText = self.displayText .. char
//             self.currentIndex = self.currentIndex + 1
            
//             -- Проигрываем звук
//             if self.config.sound and self.config.soundPath then
//                 LocalPlayer():EmitSound(self.config.soundPath, 75, 100, self.config.soundVolume)
//             end
            
//             -- Вызываем callback для символа
//             if self.config.onChar then
//                 self.config.onChar(self, char, self.currentIndex - 1)
//             end
            
//             -- Рекурсивный вызов для следующего символа
//             timer.Simple(self.config.delay, function()
//                 if IsValid(self) and self.isTyping then
//                     self:TypeNextChar()
//                 end
//             end)
//         end,
        
//         Stop = function(self)
//             self.isTyping = false
//             return self
//         end,
        
//         Skip = function(self)
//             self.displayText = self.fullText
//             self.currentIndex = #self.fullText + 1
//             self.isTyping = false
//             self.isComplete = true
            
//             if self.config.onComplete then
//                 self.config.onComplete(self)
//             end
            
//             return self
//         end,
        
//         Restart = function(self, newText)
//             if newText then
//                 self.fullText = newText
//             end
            
//             self:Stop()
//             self:Start()
            
//             return self
//         end,
        
//         SetText = function(self, newText)
//             self.fullText = newText
//             if not self.isTyping then
//                 self.displayText = ""
//                 self.currentIndex = 1
//                 self.isComplete = false
//             end
//             return self
//         end,
        
//         SetPosition = function(self, x, y)
//             self.config.x = x
//             self.config.y = y
//             return self
//         end,
        
//         SetColor = function(self, color)
//             self.config.color = color
//             return self
//         end,
        
//         SetFont = function(self, font)
//             self.config.font = font
//             return self
//         end,
        
//         Draw = function(self)
//             if self.displayText == "" then return end
            
//             local textToDraw = self.displayText
            
//             -- Добавляем курсор если нужно
//             if self.config.cursor and self.isTyping then
//                 if math.sin(CurTime() * self.config.cursorSpeed) > 0 then
//                     textToDraw = textToDraw .. self.config.cursorChar
//                 end
//             end
            
//             local x, y = self.config.x, self.config.y
            
//             -- Рисуем обводку если нужно
//             if self.config.outline then
//                 draw.SimpleTextOutlined(
//                     textToDraw,
//                     self.config.font,
//                     x, y,
//                     self.config.color,
//                     self.config.align,
//                     TEXT_ALIGN_TOP,
//                     self.config.outlineWidth,
//                     self.config.outlineColor
//                 )
//             -- Рисуем с тенью если нужно
//             elseif self.config.shadow then
//                 draw.SimpleText(
//                     textToDraw,
//                     self.config.font,
//                     x + self.config.shadowOffset,
//                     y + self.config.shadowOffset,
//                     self.config.shadowColor,
//                     self.config.align,
//                     TEXT_ALIGN_TOP
//                 )
                
//                 draw.SimpleText(
//                     textToDraw,
//                     self.config.font,
//                     x, y,
//                     self.config.color,
//                     self.config.align,
//                     TEXT_ALIGN_TOP
//                 )
//             -- Обычная отрисовка
//             else
//                 draw.SimpleText(
//                     textToDraw,
//                     self.config.font,
//                     x, y,
//                     self.config.color,
//                     self.config.align,
//                     TEXT_ALIGN_TOP
//                 )
//             end
//         end,
        
//         -- Для VGUI панелей
//         Paint = function(self, w, h)
//             self:Draw()
//         end,
        
//         -- Проверка на валидность (для таймеров)
//         IsValid = function(self)
//             return true
//         end
//     }
    
//     -- Автоматический старт если не указано иначе
//     if options and options.autoStart ~= false then
//         typingText:Start()
//     end
    
//     return typingText
// end

// -- Вспомогательная функция для быстрого создания текста
// function QuickTypingText(text, x, y, color, delay)
//     return CreateTypingText(text, {
//         x = x,
//         y = y,
//         color = color or Color(255, 255, 255),
//         delay = delay or 0.03,
//         autoStart = true
//     })
// end

// -- Примеры использования:

// -- Пример 1: Простое использование
// local simpleText = CreateTypingText("Привет, мир!", {
//     x = ScrW() / 2,
//     y = ScrH() / 2,
//     font = "ChatFont",
//     color = Color(255, 255, 0),
//     delay = 0.05,
//     autoStart = true
// })

// local storyText = CreateTypingText("Давным-давно в далекой галактике...", {
//     x = 50,
//     y = 50,
//     font = "Trebuchet24",
//     color = Color(200, 200, 255),
//     cursor = true,
//     sound = true,
    
//     -- Сохраняем данные внутри объекта
//     storyData = {
//         texts = {
//             "Давным-давно в далекой галактике...",
//             "Игрок отправился в приключение...",
//             "Конец истории!"
//         },
//         currentIndex = 1
//     },
    
//     onStart = function(self)
//         print("Часть " .. self.config.storyData.currentIndex .. ": Начало...")
//     end,
    
//     onComplete = function(self)
//         print("Часть " .. self.config.storyData.currentIndex .. ": Завершена!")
        
//         -- Увеличиваем индекс
//         self.config.storyData.currentIndex = self.config.storyData.currentIndex + 1
        
//         -- Получаем следующий текст
//         local nextText = self.config.storyData.texts[self.config.storyData.currentIndex]
        
//         if nextText then
//             timer.Simple(0.2, function()
//                 if self and self.SetText then
//                     self:SetText(nextText)
//                     self:Start()
//                 end
//             end)
//         else
//             print("Вся история завершена!")
//         end
//     end
// })

// storyText:Start()
// -- Пример 3: Текст с эффектами
// local fancyText = CreateTypingText("Стильный текст с эффектами", {
//     x = ScrW() / 2,
//     y = 100,
//     font = "DermaLarge",
//     color = Color(255, 100, 100),
//     shadow = true,
//     shadowColor = Color(0, 0, 0, 200),
//     align = TEXT_ALIGN_CENTER,
//     cursorChar = "_",
//     cursorSpeed = 3,
//     startDelay = 1 -- Начнет печататься через 1 секунду
// })

// -- Пример 4: Множество текстов
// local multiTexts = {}

// for i = 1, 5 do
//     multiTexts[i] = CreateTypingText("Текст #" .. i, {
//         x = 100,
//         y = 150 + (i * 30),
//         delay = 0.02 + (i * 0.01),
//         color = Color(100 + (i * 30), 150, 255),
//         autoStart = true
//     })
// end

// -- Хук для отрисовки всех текстов
// hook.Add("HUDPaint", "DrawAllTypingTexts", function()
//     simpleText:Draw()
//     storyText:Draw()
//     fancyText:Draw()
    
//     for _, text in ipairs(multiTexts) do
//         text:Draw()
//     end
// end)

// -- Пример 5: Управление текстом через консольные команды
// concommand.Add("start_typing", function()
//     storyText:Start()
// end)

// concommand.Add("skip_typing", function()
//     storyText:Skip()
// end)

// concommand.Add("stop_typing", function()
//     storyText:Stop()
// end)

// -- Пример 6: Создание DPanel с печатающимся текстом
// function CreateTypingTextPanel(text, options)
//     local panel = vgui.Create("DPanel")
//     panel.textObject = CreateTypingText(text, options)
    
//     function panel:Paint(w, h)
//         -- Можно нарисовать фон
//         draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 40, 200))
        
//         -- Отрисовываем текст
//         if self.textObject then
//             self.textObject:Draw()
//         end
//     end
    
//     function panel:StartTyping()
//         if self.textObject then
//             self.textObject:Start()
//         end
//     end
    
//     return panel
// end

// -- Использование панели
// local typingPanel = CreateTypingTextPanel("Текст в панели", {
//     x = 10,
//     y = 10,
//     font = "DermaDefaultBold",
//     color = Color(255, 255, 255),
//     autoStart = true
// })
// typingPanel:SetSize(300, 50)
// typingPanel:SetPos(100, 300)