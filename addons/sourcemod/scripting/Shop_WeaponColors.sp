#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

Handle g_hKv = INVALID_HANDLE;

bool g_bHasColor[MAXPLAYERS+1] = { false, ... };

int g_iClientColor[MAXPLAYERS+1][4];

public Plugin myinfo =
{
	name = "[Shop] Weapon Colors",
	description = "Grant player to buy colored weapon skins",
	author = "R1KO",
	version = "1.0",
	url = "http://www.hlmod.ru/"
};

public void OnPluginStart()
{
	if (Shop_IsStarted())
	{
		Shop_Started();
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	g_bHasColor[iClient] = false;
	SDKHook(iClient, SDKHook_WeaponCanUsePost, WeaponColors_WeaponCanUse);
}

public void OnMapStart()
{
	char buffer[256];
	if (g_hKv)
	{
		CloseHandle(g_hKv);
	}
	g_hKv = CreateKeyValues("Weapon_Colors", "", "");
	Shop_GetCfgFile(buffer, sizeof(buffer), "weapon_colors.txt");
	if (!FileToKeyValues(g_hKv, buffer))
	{
		SetFailState("Couldn't parse file %s", buffer);
	}
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void Shop_Started()
{
	if (!g_hKv)
	{
		OnMapStart();
	}
	KvRewind(g_hKv);
	char sName[64];
	char sDescription[64];
	KvGetString(g_hKv, "name", sName, sizeof(sName), "Weapon Colors");
	KvGetString(g_hKv, "description", sDescription, sizeof(sDescription), "");
	CategoryId category_id = Shop_RegisterCategory("Weapon_Colors", sName, sDescription);
	KvRewind(g_hKv);
	if (KvGotoFirstSubKey(g_hKv, true))
	{
		do {
			if (KvGetSectionName(g_hKv, sName, sizeof(sName)) && Shop_StartItem(category_id, sName))
			{
				KvGetString(g_hKv, "name", sName, sizeof(sName), sName);
				Shop_SetInfo(sName, "", KvGetNum(g_hKv, "price", 1000), KvGetNum(g_hKv, "sellprice", -1), Item_Togglable, KvGetNum(g_hKv, "duration", 604800));
				Shop_SetCustomInfo("level", KvGetNum(g_hKv, "level", 0));
				Shop_SetCallbacks(_, OnEquipItem);
				Shop_EndItem();
			}
		} while (KvGotoNextKey(g_hKv, true));
	}
	KvRewind(g_hKv);
}

public ShopAction OnEquipItem(int iClient, CategoryId category_id, char[] category, ItemId item_id, char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		g_bHasColor[iClient] = false;
		return Shop_UseOff;
	}
	Shop_ToggleClientCategoryOff(iClient, category_id);
	if (KvJumpToKey(g_hKv, item, false))
	{
		g_bHasColor[iClient] = true;
		KvGetColor(g_hKv, "color", g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);
		KvRewind(g_hKv);
		return Shop_UseOn;
	}
	PrintToChat(iClient, "Failed to use \"%s\"!.", item);
	return Shop_Raw;
}

public Action CS_OnCSWeaponDrop(int iClient, int weaponIndex)
{
	if (g_bHasColor[iClient])
	{
		SetColor(weaponIndex, 255, 255, 255, 255);
	}
	return Plugin_Continue;
}

public void WeaponColors_WeaponCanUse(int iClient, int iWeapon)
{
	if (g_bHasColor[iClient])
	{
		SetColor(iWeapon, g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);
	}
}

stock void SetColor(int iWeapon, int r, int g, int b, int a)
{
	SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iWeapon, r, g, b, a);
}
