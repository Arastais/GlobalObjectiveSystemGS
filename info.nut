/* This file was a part of MinimalGS, which is a GameScript for OpenTTD
 * Copyright (C) 2012-2013  Leif Linse
 *
 * MinimalGS is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * MinimalGS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MinimalGS; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street, 
 * Fifth Floor, Boston, MA 02110-1301 USA.
 */

require("version.nut");

/**
 * Class for all the script info. See the Game Script API for more info
 */
class GlobalObjInfo extends GSInfo {
	function GetAuthor()		{ return "Arastais"; }
	function GetName()			{ return "Global Objective System"; }
	function GetDescription() 	{ return "A game script that gives all players/companies a global challenge to achieve as the main objective of the game. Inspired heavily by Chris Sawyer's Locomotion's challenge system."; }
	function GetVersion()		{ return SELF_VERSION; }
	function MinVersionToLoad() { return LOWEST_COMPATIBLE_VERSION; }	
	function GetDate()			{ return "2022-09-20"; }
	function CreateInstance()	{ return "Main"; }
	function GetShortName()		{ return "AGOS"; } // Must be a unique 4 letter string
	function GetAPIVersion()	{ return "12"; }
	function GetURL()			{ return "https://github.com/Arastais/GlobalObjectiveSysGS"; }

	function GetSettings() {
		//Top company objective
		AddSetting({
			name = "top", 
			description = "Be the top performing company",
			flags = CONFIG_BOOLEAN,
			
			easy_value = 0, 
			medium_value = 0, 
			hard_value = 1, 
			custom_value = 0
		});
		AddSetting({
			name = "top_time", 
			description = "...within this many years",
			min_value = 0, 
			max_value = 10000, //10k
			flags = 0,
			
			easy_value = 0, 
			medium_value = 100, 
			hard_value = 40, 
			custom_value = 100
		});
		AddSetting({name = "spacer_zero", description = "", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = CONFIG_NONE, flags = 0, min_value = 0, max_value = 0});
		
	
		//Company value objective
		AddSetting({
			name = "company_value", 
			description = "Achieve a certain company value (in GBP)", 
			min_value = 0, 
			max_value = 2100000000, //2.1B
			flags = 0,
			
			easy_value = 500000, 
			medium_value = 500000, 
			hard_value = 2000000, 
			custom_value = 500000
		});
		AddSetting({
			name = "company_value_time", 
			description = "...within this many years",
			min_value = 0, 
			max_value = 10000, //10k
			flags = 0,
			
			easy_value = 0, 
			medium_value = 100, 
			hard_value = 40, 
			custom_value = 100
		});
		AddSetting({name = "spacer_one", description = "", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = CONFIG_NONE, flags = 0, min_value = 0, max_value = 0});

		//Quarterly income objective
		AddSetting({
			name = "income", 
			description = "Achieve a certain quarterly income (in GBP)", 
			min_value = 0, 
			max_value = 2000000000, //2B
			flags = 0,
			
			easy_value = 0, 
			medium_value = 50000, 
			hard_value = 200000, 
			custom_value = 50000
		});
		AddSetting({
			name = "income_time", 
			description = "...within this many years",
			min_value = 0, 
			max_value = 10000,
			flags = 0,
			
			easy_value = 0, 
			medium_value = 100, 
			hard_value = 40, 
			custom_value = 100
		});
		AddSetting({name = "spacer_two", description = "", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = CONFIG_NONE, flags = 0, min_value = 0, max_value = 0});
		
		
		//Performance rating objective
		AddSetting({
			name = "rating", 
			description = "Achieve a certain performance rating (out of 1000)", 
			min_value = 0, 
			max_value = 1000, //1k
			flags = 0,
			
			easy_value = 0, 
			medium_value = 900, 
			hard_value = 1000, 
			custom_value = 900 
		});
		AddSetting({
			name = "rating_time", 
			description = "...within this many years",
			min_value = 0, 
			max_value = 10000,
			flags = 0,
			
			easy_value = 0, 
			medium_value = 100, 
			hard_value = 40, 
			custom_value = 100
		});
		AddSetting({name = "spacer_three", description = "", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = CONFIG_NONE, flags = 0, min_value = 0, max_value = 0});
		
		
		//Quarterly cargo objective
		AddSetting({
			name = "cargo", 
			description = "Deliver a certain amount of any cargo in a single quarter", 
			min_value = 0, 
			max_value = 1000000, //1M
			flags = 0,
			
			easy_value = 0, 
			medium_value = 1000, 
			hard_value = 20000, 
			custom_value = 1000 
		});
		AddSetting({
			name = "cargo_time", 
			description = "...within this many years",
			min_value = 0, 
			max_value = 10000,
			flags = 0,
			
			easy_value = 0, 
			medium_value = 100, 
			hard_value = 40, 
			custom_value = 100
		});
		AddSetting({name = "spacer_four", description = "", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = CONFIG_NONE, flags = 0, min_value = 0, max_value = 0});
		
		
		//Bank money objective
		AddSetting({
			name = "bank", 
			description = "Have a certain amount of money in the bank (minus loan; in GBP)", 
			min_value = 0, 
			max_value = 2100000000, //2.1B
			flags = 0,
			
			easy_value = 0, 
			medium_value = 5000000, 
			hard_value = 5000000000, 
			custom_value = 5000000
		});
		AddSetting({
			name = "bank_time", 
			description = "...within this many years",
			min_value = 0, 
			max_value = 10000,
			flags = 0,
			
			easy_value = 0, 
			medium_value = 100, 
			hard_value = 40, 
			custom_value = 100
		});
		
		
		
		//'Off' Labels
		AddLabels("top_time", { _0 = "Off", });
		AddLabels("company_value", { _0 = "Off", });
		AddLabels("company_value_time", { _0 = "Off", });
		AddLabels("income", { _0 = "Off", });
		AddLabels("income_time", { _0 = "Off", });
		AddLabels("rating", { _0 = "Off", });
		AddLabels("rating_time", { _0 = "Off", });
		AddLabels("cargo", { _0 = "Off", });
		AddLabels("cargo_time", { _0 = "Off", });
		AddLabels("bank", { _0 = "Off", });
		AddLabels("bank_time", { _0 = "Off", });
		
		//Spacer labels
		AddLabels("spacer_zero", { _0 = "" });
		AddLabels("spacer_one", { _0 = "" });
		AddLabels("spacer_two", { _0 = "" });
		AddLabels("spacer_three", { _0 = "" });
		AddLabels("spacer_four", { _0 = "" });
	}
}

RegisterGS(GlobalObjInfo());
