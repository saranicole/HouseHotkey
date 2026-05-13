local HH = HouseHotkey

local LAM = LibHarvensAddonSettings

local LRM = LibRadialMenu

local LIBRADIAL_WHEEL = HOTBAR_CATEGORY_MAX_VALUE + 100

--Credit to LibConsoleDialogs for the technique
local dialogSettings = LAM.AddonSettings:Subclass()

function HH:CreateDialog(title)
	local options = {
		allowDefaults = true,
		allowRefresh = false
	}
	local dialog = dialogSettings:New(title, options)
	dialog.headerData = {titleText = title}
	return dialog
end

HH.dialogCallStack = {}

local orgSelect = dialogSettings.Select
function dialogSettings:Show()
	LAM:Initialize()
	if self.container == nil then
		self.container = LAM.container
		self:InitHandlers()
	end
	if LAM.scene:IsShowing() and currentSettings then
		HH.dialogCallStack[#HH.dialogCallStack + 1] = currentSettings
	end
	orgSelect(self)
	if self.selected then
		currentSettings = self
	end

	ZO_GamepadGenericHeader_RefreshData(LAM.scrollList.header, self.headerData)

	if LAM.scene:IsShowing() then
		self:RefreshSelection()
	else
		SCENE_MANAGER:Push(LAM.scene:GetName())
	end
end

local wheelOptions = {
  { name = GetString(SI_HOTBARCATEGORY10), data = HOTBAR_CATEGORY_QUICKSLOT_WHEEL},
  { name = GetString(SI_HOTBARCATEGORY13), data = HOTBAR_CATEGORY_ALLY_WHEEL},
  { name = GetString(SI_HOTBARCATEGORY12), data = HOTBAR_CATEGORY_MEMENTO_WHEEL},
  { name = GetString(SI_HOTBARCATEGORY14), data = HOTBAR_CATEGORY_TOOL_WHEEL},
  { name = GetString(SI_HOTBARCATEGORY11), data = HOTBAR_CATEGORY_EMOTE_WHEEL},
}


if LRM ~= nil then
  table.insert(wheelOptions, { name = HH.Lang.LRM_WHEEL, data = LIBRADIAL_WHEEL})
end

local slotOptions = {
      { name = "1 - N", data = 4 },
      { name = "2 - NW", data = 5 },
      { name = "3 - W", data = 6 },
      { name = "4 - SW", data = 7 },
      { name = "5 - S", data = 8 },
      { name = "6 - SE", data = 1 },
      { name = "7 - E", data = 2 },
      { name = "8 - NE", data = 3 },
    }
    
local function getSelectedHouse(data)
    local house
    if data then
      house = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(data.dataSource.collectibleId)
    elseif GAMEPAD_COLLECTIONS_BOOK and GAMEPAD_COLLECTIONS_BOOK.collectionList and GAMEPAD_COLLECTIONS_BOOK.collectionList.list then
      selectedItem = GAMEPAD_COLLECTIONS_BOOK.collectionList.list:GetTargetData()
      if selectedItem and selectedItem.dataSource.categoryData and selectedItem.dataSource.categoryData.IsHousingCategory and not selectedItem.dataSource:IsLocked() then
        house = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(selectedItem.dataSource.collectibleId)
      end
    end
    return house
end

HH.selectedHouse = nil

function HH.AddAssignHouse(newState)
  local HH_Lang = HH.Lang
  local UseExterior = false
  local Icon, IconName, Category, CategoryName, SlotNum
  
  HH.selectedHouse = getSelectedHouse()
  
  HH.assignHouse = HH:CreateDialog(HH.Lang.HOTBAR_OPTIONS)

  HH.assignHouse:AddSetting {
    type = LAM.ST_LABEL,
    label = function()
      return HH_Lang.CREATE_QUICKSLOT
    end,
  }

  HH.assignHouse:AddSetting {
    type = LAM.ST_LABEL,
    label = function()
      if HH.selectedHouse and HH.selectedHouse:GetFormattedName() then
        return "|cebc034"..HH.selectedHouse:GetFormattedName().."|r"
      end
      return ""
    end,
  }
  
  HH.assignHouse:AddSetting({
    type = LAM.ST_DROPDOWN,
    label = HH_Lang.WHEEL_CATEGORY,
    items = wheelOptions,
    getFunction = function() return CategoryName or GetString(SI_HOTBARCATEGORY10) end,
    setFunction = function(var, itemName, itemData)
      CategoryName = itemName
      Category = tonumber(itemData.data)
      HH.assignHouse:UpdateControls()
    end,
    default = GetString(SI_HOTBARCATEGORY10),
  })
  
  HH.assignHouse:AddSetting {
      type = LAM.ST_DROPDOWN,
      label = HH_Lang.WHEEL_SLOT,
      items = function()
        if Category == LIBRADIAL_WHEEL then
          local slotsObj = {}
          for i = 1, LRM.vars.numSlots do 
            table.insert(slotsObj, { name = tostring(i), data = i })
          end
          return slotsObj
        else
          return slotOptions
        end
      end,
      getFunction = function() return EntryIndexName or tostring(#LRM.registeredEntries + 1) end,
      setFunction = function(var, itemName, itemData)
        EntryIndexName = itemName
        EntryIndex = tonumber(itemData.data)
      end,
    }
  
  HH.assignHouse:AddSetting({
    type = LAM.ST_ICONPICKER,
    label = HH_Lang.WHEEL_ICON,
    items = HH.IconList,
    getFunction = function() return Icon  end,
    setFunction = function(var, iconIndex, iconPath)
      IconName = iconPath
      Icon = iconIndex
    end,
  })
  
  HH.assignHouse:AddSetting({
    type = LAM.ST_CHECKBOX,
    label = HH.Lang.HOUSE_EXTERIOR,
    default = false,
    setFunction = function(state)
        UseExterior = state
    end,
    getFunction = function()
        return UseExterior
    end
  })
  
  HH.assignHouse:AddSetting {
    type = LAM.ST_BUTTON,
    label = HH_Lang.WHEEL_APPLY,
    buttonText = HH_Lang.WHEEL_APPLY,
    clickHandler  = function()
      HH.SV.Command[Category or HOTBAR_CATEGORY_QUICKSLOT_WHEEL][EntryIndex or 4] = {
        ["name"] = HH.selectedHouse:GetFormattedName(),
        ["icon"] = IconName or HH.IconList[1],
        ["house"] = HH.selectedHouse:GetReferenceId(),
        ["exterior"] = UseExterior or false,
        ["houseName"] = HH.selectedHouse:GetFormattedName(),
        ["houseOwner"] = HH.selectedHouse.owner or "self",
        ["slotNum"] = EntryIndex
      }
      if LRM ~= nil then
        HH.AssignLRM(
          HH.selectedHouse:GetFormattedName(), 
          HH.selectedHouse:GetReferenceId(), 
          IconName or HH.IconList[1], 
          HH.selectedHouse.owner or "self", 
          UseExterior, 
          EntryIndex
        )
      end
      Status = HH.Lang.STATUS_ADDED
      HH.assignHouse:UpdateControls()
    end
  }
  HH.assignHouse:AddSetting {
    type = LAM.ST_LABEL,
    label = function()
      return Status or " "
    end
  }
    HH.assign = {
      alignment = KEYBIND_STRIP_ALIGN_LEFT,
      {

          name = HH.Lang.ADD_TO_HOTBAR,
          keybind = "UI_SHORTCUT_QUATERNARY",
          visible = function()
            if GAMEPAD_COLLECTIONS_BOOK.currentList and GAMEPAD_COLLECTIONS_BOOK.currentList.list then 
            selectedItem = GAMEPAD_COLLECTIONS_BOOK:GetCurrentTargetData()
            if selectedItem then
              local house = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(selectedItem.dataSource.collectibleId)
              if house and not house:IsLocked() and selectedItem.dataSource.categoryData.IsHousingCategory then
                return true
              end
            end
            return false
          end
          end,
          callback = function()
              HH.assignHouse:Show()
          end,
        },
      }
    KEYBIND_STRIP:AddKeybindButtonGroup(HH.assign)
    GAMEPAD_COLLECTIONS_BOOK.currentList.list:SetOnSelectedDataChangedCallback(function(list, selectedData)
        HH.selectedHouse = getSelectedHouse(selectedData)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(HH.assign)
    end)
end