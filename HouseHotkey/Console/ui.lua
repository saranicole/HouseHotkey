local HH = HouseHotkey

function HH.AddAssignHouse(newState)

  local entryData = ZO_GamepadEntryData:New(HH.Lang.WHEEL_APPLY)
  entryData.setup = ZO_SharedGamepadEntry_OnSetup
  entryData.callback = function()
    ZO_Dialogs_ReleaseDialogOnButtonPress("HH_GAMEPAD_OWNED_HOUSE_DIALOG")
  end
  
  ZO_Dialogs_RegisterCustomDialog("HH_GAMEPAD_OWNED_HOUSE_DIALOG",
  {
    gamepadInfo = {
      dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
    },
    setup = function(dialog)
      dialog:setupFunc()
    end,
    title = {
      text = HH.Lang.HOTBAR_OPTIONS,
    },
    blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.
  
    canQueue = true,
    parametricList =
	{
		{
			template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
			templateData = {
          text = HH.Lang.HOUSE_EXTERIOR,
          setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
              control.checkBox.dialog = data.dialog
              ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
          end,
          checked = function(data)
              return data.dialog.UseExterior or false
          end,
          setChecked = function(checkBox, checked)
              checkBox.dialog.UseExterior = checked
          end,
          callback = function(dialog)
              local targetControl = dialog.entryList:GetTargetControl()
              ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
          end,
			  },
		  },
		  {
				template = "ZO_GamepadItemEntryTemplate",
				entryData = entryData,
			}
		},
    buttons = {
      {
        keybind = "DIALOG_PRIMARY",
        text = SI_GAMEPAD_SELECT_OPTION,
        callback =  function(dialog)
          local data = dialog.entryList:GetTargetData()
          if data.callback then
            data.callback(dialog)
          end
          if GAMEPAD_COLLECTIONS_BOOK.currentList and GAMEPAD_COLLECTIONS_BOOK.currentList.list then 
            selectedItem = GAMEPAD_COLLECTIONS_BOOK:GetCurrentTargetData()
            if selectedItem and selectedItem.dataSource:IsInstanceOf(ZO_CollectibleData) and selectedItem.dataSource.categoryData.IsHousingCategory then
              local house = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(selectedItem.dataSource.collectibleId)
              HH.AssignLRM(house, dialog.UseExterior)
            end
          end
        end,
      },
  
      {
        keybind = "DIALOG_NEGATIVE",
        text = SI_DIALOG_CLOSE,
        callback = function()
          ZO_Dialogs_ReleaseDialogOnButtonPress("HH_GAMEPAD_OWNED_HOUSE_DIALOG")
        end,
      },
    },
  })

--   if HH.assign == nil then
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
              ZO_Dialogs_ShowGamepadDialog("HH_GAMEPAD_OWNED_HOUSE_DIALOG")
          end,
        },
      }
    KEYBIND_STRIP:AddKeybindButtonGroup(HH.assign)
    GAMEPAD_COLLECTIONS_BOOK.currentList.list:SetOnSelectedDataChangedCallback(function()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(HH.assign)
    end)
--   end
end