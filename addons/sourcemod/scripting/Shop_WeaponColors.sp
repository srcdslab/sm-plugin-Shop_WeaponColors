#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

KeyValues g_hKv = null;

bool g_bHasColor[MAXPLAYERS+1] = { false, ... };

int g_iClientColor[MAXPLAYERS+1][4];

public Plugin myinfo =
{
	name = "[Shop] Weapon Colors",
	description = "Grant player to buy colored weapon skins",
	author = "R1KO",
	version = "1.1",
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
		delete g_hKv;
	}
	g_hKv = new KeyValues("Weapon_Colors", "", "");
	Shop_GetCfgFile(buffer, sizeof(buffer), "weapon_colors.txt");
	if (!g_hKv.ImportFromFile(buffer))
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
	g_hKv.Rewind();
	char sName[64];
	char sDescription[64];
	g_hKv.GetString("name", sName, sizeof(sName), "Weapon Colors");
	g_hKv.GetString("description", sDescription, sizeof(sDescription), "");
	CategoryId category_id = Shop_RegisterCategory("Weapon_Colors", sName, sDescription);
	g_hKv.Rewind();
	if (g_hKv.GotoFirstSubKey(true))
	{
		do {
			if (g_hKv.GetSectionName(sName, sizeof(sName)) && Shop_StartItem(category_id, sName))
			{
				g_hKv.GetString("name", sName, sizeof(sName), sName);
				Shop_SetInfo(sName, "", g_hKv.GetNum("price", 1000), g_hKv.GetNum("sellprice", -1), Item_Togglable, g_hKv.GetNum("duration", 604800));
				Shop_SetCustomInfo("level", g_hKv.GetNum("level", 0));
				Shop_SetCallbacks(_, OnEquipItem);
				Shop_EndItem();
			}
		} while (g_hKv.GotoNextKey(true));
	}
	g_hKv.Rewind();
}

public ShopAction OnEquipItem(int iClient, CategoryId category_id, char[] category, ItemId item_id, char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		g_bHasColor[iClient] = false;
		return Shop_UseOff;
	}
	Shop_ToggleClientCategoryOff(iClient, category_id);
	if (g_hKv.JumpToKey(item, false))
	{
		g_bHasColor[iClient] = true;
		g_hKv.GetColor("color", g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);
		g_hKv.Rewind();
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
