-- Local API
local CreateFrame = CreateFrame
local debugstack = debugstack

-- Local addon data structure
local Addon = CreateFrame("Frame")

Addon.name = "AdventureGuideBosses"
Addon.errors = false
Addon.savesVersion = 1

-- Globally available addon data structure
_G[Addon.name] = Addon

local EJOrder = {
-- UiMapID   Boss Button Order                   Raid Wing Label Index, Key is Boss Index, Value is dungeonID
  [409]  = {{1,2,3,4,5,6,7,8},                  {[1]=416,[5]=417}},                          -- Dragon Soul
  [471]  = {{1,2,3,4,5,6},                      {[1]=527,[4]=528}},                          -- Mogu'shan Vaults
  [474]  = {{1,2,3,4,5,6},                      {[1]=529,[4]=530}},                          -- Heart of Fear
  [508]  = {{1,2,3,4,5,6,7,8,9,10,11,12},       {[1]=610,[4]=611,[7]=612,[10]=613}},         -- Throne of Thunder
  [557]  = {{1,2,3,4,5,6,7,8,9,10,11,12,13,14}, {[1]=716,[5]=717,[9]=724,[12]=725}},         -- Siege of Orgrimmar
  [612]  = {{1,2,4,3,5,6,7},                    {[1]=849,[3]=850,[7]=851}},                  -- Highmaul
  [597]  = {{4,1,7,2,5,8,3,6,9,10},             {[4]=847,[2]=846,[3]=848,[10]=823}},         -- Blackrock Foundry
  [661]  = {{1,2,3,5,4,6,7,8,11,9,10,12,13},    {[1]=982,[5]=983,[7]=984,[9]=985,[13]=986}}, -- Hellfire Citadel
  [777]  = {{1,2,3,4,5,6,7},                    {[1]=1287,[4]=1288,[7]=1289}},               -- The Emerald Nightmare
  [764]  = {{1,2,3,4,7,8,5,6,9,10},             {[1]=1290,[4]=1291,[5]=1292,[10]=1293}},     -- The Nighthold
  [850]  = {{1,3,5,2,4,6,7,8,9},                {[1]=1494,[2]=1495,[7]=1496,[9]=1497}},      -- Tomb of Sargeras
  [909]  = {{1,2,3,4,5,6,7,8,9,10,11},          {[1]=1610,[4]=1611,[7]=1612,[10]=1613}},     -- Antorus, the Burning Throne
  [1148] = {{1,2,4,3,5,6,7,8},                  {[1]=1731,[3]=1732,[7]=1733}},               -- Uldir
  [1352] = {{1,3,2,4,5,6,7,8},                  {[1]=1945,[4]=1946,[7]=1947}},               -- Battle of Dazar'alor (Alliance)
  [1358] = {{1,2,3,4,5,6,7,8},                  {[1]=1948,[4]=1949,[7]=1950}},               -- Battle of Dazar'alor (Horde)
}

--
-- Processes WoW events in a protected call.
-- @param event The event.
-- @param ...   The event parameters.
--
function Addon:OnEventP(event, ...)
  if event == "ADDON_LOADED" then
    local name = select(1, ...)
    if name == "Blizzard_EncounterJournal" then
      -- Create a boss button, on which to attach this addon
      local bossButton = _G["EncounterJournalBossButton1"]
      if not bossButton then
        bossButton =
        CreateFrame(
          "BUTTON",
          "EncounterJournalBossButton1",
          EncounterJournal.encounter.bossesFrame,
          "EncounterBossButtonTemplate"
        )
        bossButton:SetPoint("TOPLEFT", EncounterJournal.encounter.bossesFrame, "TOPLEFT", 0, -10)
      end
      -- Attach addon
      Addon.EJ = CreateFrame("Frame", nil, bossButton)
      Addon.EJ:SetScript(
        "OnShow",
        function (self)
          -- Hide any visible wing labels
          local wingIndex = 1
          local wingFrame = _G["EncounterJournalWingFrame"..wingIndex]
          local wingLabel = _G["EncounterJournalWingLabel"..wingIndex]
          while wingFrame do
            wingFrame:Hide()
            wingIndex = wingIndex + 1
            wingFrame = _G["EncounterJournalWingFrame"..wingIndex]
          end
          wingIndex = 1
          -- Reset boss button positions
          local bossIndex = 1
          bossButton = _G["EncounterJournalBossButton"..bossIndex]
          while bossButton do
            if bossIndex > 1 then
              bossButton:SetPoint("TOPLEFT", _G["EncounterJournalBossButton"..(bossIndex-1)], "BOTTOMLEFT", 0, -15)
            else
              bossButton:SetPoint("TOPLEFT", EncounterJournal.encounter.bossesFrame, "TOPLEFT", 0, -10)
            end
            bossIndex = bossIndex + 1
            bossButton = _G["EncounterJournalBossButton"..bossIndex]
          end
          -- Rearrange boss buttons and add wing labels
          local UiMapID = select(7, EJ_GetInstanceInfo())
          if EJOrder[UiMapID] then
            local order = EJOrder[UiMapID][1]
            for i = 1, #order do
              bossButton = _G["EncounterJournalBossButton"..order[i]]
              if not bossButton then
                -- Blizzard_EncounterJournal addon hasn't fully loaded this page yet, quit for now
                return
              end
              local rfinfo = EJOrder[UiMapID][2][order[i]]
              if rfinfo then
                -- Start of a new wing, add a label for it
                wingFrame = _G["EncounterJournalWingFrame"..wingIndex]
                wingLabel = _G["EncounterJournalWingLabel"..wingIndex]
                if not wingFrame then
                  wingFrame =
                  CreateFrame(
                    "Frame",
                    "EncounterJournalWingFrame"..wingIndex,
                    EncounterJournal.encounter.bossesFrame
                  )
                  wingLabel =
                  wingFrame:CreateFontString(
                    "EncounterJournalWingLabel"..wingIndex,
                    "ARTWORK",
                    "QuestTitleFont"
                  )
                end
                local label = GetLFGDungeonInfo(rfinfo)
                wingLabel:SetText(label)
                wingFrame:Show()
                if i > 1 then
                  wingLabel:SetPoint("TOPLEFT", _G["EncounterJournalBossButton"..order[i-1]], "BOTTOMLEFT", 0, -15)
                else
                  wingLabel:SetPoint("TOPLEFT", EncounterJournal.encounter.bossesFrame, "TOPLEFT", 0, -10)
                end
                bossButton:SetPoint("TOPLEFT", wingLabel, "BOTTOMLEFT", 0, -15)
                wingIndex = wingIndex + 1
              else
                if i > 1 then
                  bossButton:SetPoint("TOPLEFT", _G["EncounterJournalBossButton"..order[i-1]], "BOTTOMLEFT", 0, -15)
                else
                  bossButton:SetPoint("TOPLEFT", EncounterJournal.encounter.bossesFrame, "TOPLEFT", 0, -10)
                end
              end
            end
          end
        end
      )
    elseif name ~= Addon.name then
      return
    end
  elseif event == "PLAYER_LOGIN" then
    if not saves then
      -- Fresh install
      saves = {version = Addon.savesVersion}
    else
      local dataConvert = {
        -- [1] = function(savesTable)
              -- -- Code to convert to savesVersion 2
              -- end
      }
      while dataConvert[saves.version] do
        -- Call the data conversion code, and increment saves version
        dataConvert[saves.version](saves)
        saves.version = saves.version + 1
      end
    end
  end
end

--
-- Executes event code in a protected call.
-- @param ... Event and event arguements.
--
function Addon:OnEvent(...)
  Addon.xpcall(Addon.OnEventP, Addon, ...)
end

--
-- Performs a protected call that will, for errors, have a stacktrace.
-- @param f   The function to call.
-- @param ... The function parameters.
--
function Addon.xpcall(f, ...)
  local args = {...}
  local success, values = xpcall(
    function()
      return {f(unpack(args))}
    end,
    function(msg)
      return {msg, debugstack()}
    end
  )
  if not values or type(values) ~= "table" then
    return
  end
  if not success and Addon.errors then
    print(values[1], values[2])
  end
  return unpack(values)
end

Addon:SetScript("OnEvent", Addon.OnEvent)
Addon:RegisterEvent("ADDON_LOADED")
Addon:RegisterEvent("PLAYER_LOGIN")
