/*
 * This file was a part of MinimalGS, which is a GameScript for OpenTTD
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

require("version.nut"); // get SELF_VERSION
require("goals.nut");
require("util.nut");
//..

//ObjIdx and VictoryState are in goals.nut but aren't imported/seen in main.nut for some reason, so they cannot be used
//It has to be here as well to be used in this file. The altnerative is to put them in the Goals class and call Goals.TOP for example.
///Enum used to represent the index of an objective
enum ObjIdx {
	TOP,
	COMPANY,
	INCOME,
	RATING,
	CARGO,
	BANK,
	NUM_OBJ
}
///Enum that represents the state of victory for a company
enum VictoryState{
	NONE,
	FAILED,
	ACHIEVED
}
///Enum that represents the state of the story
enum StoryState{
	NONE,
	INIT,
	SHOWN
}

/**
 * Main class of the script
 */
class Main extends GSController 
{
	_loaded_data = null; ///< table for data loaded from the savegame
	_loaded_from_version = null; ///< version of the gamescript that is loaded from a save
	_init_done = null; ///< bool to signifiy yif Init() function has finished
	_company_data = null; ///< nested table with all company related data
	_start_year = null; ///< start year of the game/save
	_objs = null; ///< objective data (configured goal amounts and associated texts
	_story_id = null; ///< id for the story page
	_story_state = null; ///< state of the story page (has it been created? has it been shown to the user?
	_global_goals = null; ///< array for the ids of the current global goals
	_top_rating = null; ///< the value of the top performance rating
	_victories = null; ///< number of victories that have been achieved
	_rankings_order = null; ///< array that holds the order of which companies are ranked in a given cycle
	_completions = null; ///< array that holds which companies have completed a given objective in a given cycle
	_expired_objs = null; ///< objectives that have expired due to time constraints
	_Goals = null; ///< the Goals class instance

	/*
	 * This method is called when your GS is constructed.
	 * It is recommended to only do basic initialization of member variables
	 * here.
	 * Many API functions are unavailable from the constructor. Instead do
	 * or call most of your initialization code from Main::Init.
	 */
	constructor()
	{
		this._init_done = false;
		this._loaded_data = null;
		this._loaded_from_version = null;
		//The following are saved with the savegame
		_company_data = {};
		_start_year = null;
		_objs = array(0);
		_story_id = null;
		_story_state = StoryState.NONE;
		_top_rating = -1;
		_expired_objs = array(ObjIdx.NUM_OBJ, false);
		_victories = 0;
		_global_goals = array(0);
		//The following do not need to be saved since they are reset every update
		_rankings_order = array(ObjIdx.NUM_OBJ, array(0));
		_completions = array(ObjIdx.NUM_OBJ, array(0));
		_Goals = null; //delayed until Init();
	}
}

/**
 * Start the script. This method is called by OpenTTD after the constructor, and after calling
 * Load() in case the game was loaded from a save game. You should never
 * return back from this method. (if you do, the script will crash)
 *
 * Start() contains of two main parts. First initialization (which is
 * located in Init), and then the main loop.
 */
function Main::Start()
{
	// Some OpenTTD versions are affected by a bug where all API methods
	// that create things in the game world during world generation will
	// return object id 0 even if the created object has a different ID. 
	// In that case, the easiest workaround is to delay Init until the 
	// game has started.
	local v = GSController.GetVersion();
	local version = {
		Major = (v & 0xF0000000) >> 28,
		Minor = (v & 0x0F000000) >> 24,
		Rev = v & 0x0007FFFF,
	}
	if (((version.Major == 0 || (version.Major == 1 && version.Minor <= 3)) && version.Rev < 25339) || version.Rev < 25305) {
		GSController.Sleep(1);
	}
	
	//Initialize
	this.Init();

	// Wait for the game to start (or more correctly, tell OpenTTD to not
	// execute our GS further in world generation)
	GSController.Sleep(1);

	// Game has now started and if it is a single player game, company 0 exists and is the human company.
	//if the story page has not been shown yet, show it and mark it as such
	if(_story_state != StoryState.SHOWN){
		GSStoryPage.Show(_story_id);
		_story_state = StoryState.SHOWN;
	}
	
	// Main Game Script loop
	local last_loop_date = GSDate.GetCurrentDate();
	local last_month = GSDate.GetMonth(last_loop_date);
	local last_quarter = (last_month - 1) / 3;
	while (true) {
		local loop_start_tick = GSController.GetTick();

		//dont run the script if the game is paused (for efficiency)
		if(!GSGame.IsPaused()){
			// Handle incoming messages from OpenTTD
			this.HandleEvents();
			
			//get the current date, month, and quarter
			local current_date = GSDate.GetCurrentDate();
			local current_month = GSDate.GetMonth(current_date);
			local current_quarter = (current_month - 1) / 3;
			local quarter_update = false; //signifies if a end of quarter update has occured
			if (last_loop_date != null) {
				////Util.Log("Q"+current_quarter + " M" + current_month);
				local year = GSDate.GetYear(current_date);
				//if we are on a new year, run the end of year actions
				if (year != GSDate.GetYear(last_loop_date))
					this.EndOfYear(false);
				//if we are on a new year, run the end of quarter actions
				//also store if we have made an update to company data values this quarter
				if (current_quarter != last_quarter)
					quarter_update = this.EndOfQuarter(false);
				this.EndOfDayCycle(false, quarter_update);
			}
			last_loop_date = current_date;
			last_month = current_month;
			last_quarter = current_quarter;
		}
		// Loop with a frequency of five days
		local ticks_used = GSController.GetTick() - loop_start_tick;
		GSController.Sleep(max(1, 5 * 74 - ticks_used));
	}
}

/**
 * Initialize the Game Script.
 * As long as you never call Sleep() and the user got a new enough OpenTTD
 * version, all initialization happens while the world generation screen
 * is shown. This means that even in single player, company 0 doesn't yet
 * exist. The benefit of doing initialization in world gen is that commands
 * that alter the game world are much cheaper before the game starts.
 */
function Main::Init()
{
	if (this._loaded_data != null) {
		// Copy loaded data from this._loaded_data to this.*
		// or do whatever you like with the loaded data
		//NOTE: this creates references to this._loaded_data.*
		//if this is not intended then clone(...) should be used to create copies
		_company_data=this._loaded_data.company_data;
		_start_year=this._loaded_data.start_year,
		_objs=this._loaded_data.objs,
		_story_id=this._loaded_data.story_id,
		_top_rating=this._loaded_data.top_rating,
		_expired_objs=this._loaded_data.expired_objs,
		_victories=this._loaded_data.victories,
		_global_goals = this._loaded_data.global_goals,
		_story_state = this._loaded_data.story_state
	} else {
		//Set the starting year
		_start_year = GSDate.GetYear(GSDate.GetCurrentDate());
	    Util.Log("Starting in year " + _start_year);
		//Construct objective values array (basically just store fixed values for easy access)
		_objs = [
			[GSController.GetSetting("top"), GSController.GetSetting("top_time"), GSText.OBJ_TOP, GSText.GOAL_PROG_COMMA],
			[GSController.GetSetting("company_value"), GSController.GetSetting("company_value_time"), GSText.OBJ_COMPANY, GSText.GOAL_PROG_CURR],
			[GSController.GetSetting("income"), GSController.GetSetting("income_time"), GSText.OBJ_INCOME, GSText.GOAL_PROG_CURR],
			[GSController.GetSetting("rating"), GSController.GetSetting("rating_time"), GSText.OBJ_RATING, GSText.GOAL_PROG_COMMA],
			[GSController.GetSetting("cargo"), GSController.GetSetting("cargo_time"), GSText.OBJ_CARGO, GSText.GOAL_PROG_COMMA],
			[GSController.GetSetting("bank"), GSController.GetSetting("bank_time"), GSText.OBJ_BANK, GSText.GOAL_PROG_CURR]
		];
		//Create the story page and store its id
		_story_id = Goals.CreateStoryPage();
	}
	//Construct Goals class instance (includes objective titles)
	_Goals = Goals(_company_data, _global_goals, _objs, _start_year, _story_id);
	//if the story page body has't been initialzed, do so now and mark the story state as such
	if(_story_state == StoryState.NONE) {
		_Goals.CreateStoryBody();
		_story_state = StoryState.INIT;
	}
	// Indicate that all data structures has been initialized/restored.
	this._init_done = true;
	this._loaded_data = null; // the _loaded_data table has no more use now after that _init_done is true.
}

/**
 * Handles incoming events from OpenTTD.
 */
function Main::HandleEvents()
{
	if(GSEventController.IsEventWaiting()) {
		local ev = GSEventController.GetNextEvent();
		if (ev == null) return;

		local ev_type = ev.GetEventType();
		switch (ev_type) {
			case GSEvent.ET_COMPANY_NEW: {
				//Convert the event
				local company_event = GSEventCompanyNew.Convert(ev);
				//get the new company's id
				local company_id = company_event.GetCompanyID();
				//add a table slot for the new company
				_company_data.rawset(company_id, {
					indiv=array(ObjIdx.NUM_OBJ, null),  //the goal ID for the company goal
					global=array(ObjIdx.NUM_OBJ, null), //the goal ID for the global goal
					amt=array(ObjIdx.NUM_OBJ, 0), //the raw amount toward the objective
					failed=array(ObjIdx.NUM_OBJ, false), //if the objective is marked as failed
					rankings=array(ObjIdx.NUM_OBJ, null), //its rankings relative to other companies
					victory_cond=VictoryState.NONE //if this company should be ignored when checking for a victory 
				});
				//create local goals for the new company
				_Goals.CreateLocalGoals(company_id);
				//Run all the updates/checks for the new company
				this.EndOfYear(true);
				local q = this.EndOfQuarter(true);
				this.EndOfDayCycle(true, q);
				//Log company join
				Util.Log("New company #" + company_id + " has joined");
				break;
			}

			case GSEvent.ET_COMPANY_BANKRUPT: {
				//Convert the event
				local bankrupt_event = GSEventCompanyBankrupt.Convert(ev);
				//get the bankrupt company's id
				local company_id = company_event.GetCompanyID();
				//if the bankrupt company in question hasn't already completed all objectives
				if(goal_tbl.victory_cond != VictoryState.ACHIEVED){
					//mark the company's victory as failed
					goal_tbl.victory_cond = VictoryState.FAILED;
					//anounce it to them
					GSNews.Create(GSNews.NT_GENERAL, GSText(GSText.VIC_FAIL_BANKRUPT, i), company_id, GSNews.NR_NONE, company_id);
					//update their goal's text color to red
					UpdateGoalsColor(company_id);
				}
			}
			case GSEvent.ET_COMPANY_MERGER: {
				//Convert the event
				local merge_event = GSEventCompanyMerger.Convert(ev);
				//get the old company's id
				local old_company_id = company_event.GetOldCompanyID();
				//delete the old company from the data table (since it has been merged to another one)
				delete _company_data[old_company_id];
			}
		}
	}
}

/**
 * Check for daily objective changes and for any victories
 *
 * Called by our main loop when a new day has been reached within the cycle
 * In other words, once every loop, it checks for changes in the bank balance objective
 * and any victories from any company
 * @param init If we are intializing a company. If true, it will forcefully update the goals.
 * @param quarter_update if there was an update in a quarterly objective. If true, it will forcefully update the global goals.
 */
function Main::EndOfDayCycle(init, quarter_update)
{
	/*Check bank balance*/
	local idx = ObjIdx.BANK;
	local change = init;
	//if the objective is active
	if(_Goals.IsObjActive(idx))
		//update its value if there's a change
		if(UpdateValue(idx, init))
			//mark if there was a change
			change = true;
	//If there was a quartlery objective update, or if there was a change in values, update the global goals
	if(change || quarter_update) _Goals.UpdateGlobalGoals(_rankings_order, _top_rating);
	/* Check for a victory */
	local victory_ids = array(0);
	//for each company
	foreach(company_id, goal_tbl in _company_data){
		//if they're marked as failing or already achieving victory, skip this company
		if(goal_tbl.victory_cond != VictoryState.NONE) continue;
		//assume they have a victory
		local victory = true;
		//for each goal/objective
		for(local i = 0; i < goal_tbl.indiv.len(); i++){
			//if the company doesnt have this goal (i.e. if the objective is not active), skip this objective
			if(goal_tbl.indiv[i] == null) continue;
			//if they have not completed any goal, or if they are not the top rated company (if that objective is active), they have not achieved victory
			if((i != ObjIdx.TOP && !GSGoal.IsCompleted(goal_tbl.indiv[i])) || (i == ObjIdx.TOP && goal_tbl.amt[i] < _top_rating)) victory = false;
		}
		//if there was noting found for them not to achieve victory, queue them to be awared a victory.
		if(victory) victory_ids.append(company_id);
	}
	
	if(victory_ids.len() > 0){
		local place = _victories + 1;
		//for every company which has been marked as achieving victory
		foreach(id in victory_ids){
			//log their victory
			Util.Log("Company #" + id + " has won and acieved rank " + place + "!");
			//mark their victory condition has having achieved victory
			_company_data[id].victory_cond = VictoryState.ACHIEVED;
			//create the text for their victory
			local vic_text = GSText(GSText.VIC, id,  place, GSText(Util.GetRankSuffix(place)));
			//if they are the first one to achieve victory
			if(_victories == 0) {
				//change their text to one specifically for first place
				vic_text = GSText(GSText.VIC_FIRST, id);
				//if we're in single player
				if(!GSGame.IsMultiplayer()){
					//also add to the global story page that the single player has achieved victory
					//then show the story page to them
					foreach(text in [" ", GSText(GSText.VIC_SINGLEPLAYER)])
						GSStoryPage.NewElement(_story_id, GSStoryPage.SPET_TEXT, 0, text); 
						GSStoryPage.Show(_story_id);
				}
			}
			//anounce their victory
			GSNews.Create(GSNews.NT_GENERAL, vic_text, GSCompany.COMPANY_INVALID, GSNews.NR_NONE, id);
		}
		//mark how many victories have been made so far
		_victories += victory_ids.len();
		//update the global goals to reflect which companies have achieved victory (i.e. change the text to green)
		_Goals.UpdateGlobalGoals(_rankings_order, _top_rating);
	}
	
}

/**
 * Check for quarterly objective changes and for any victories
 *
 * Called by our main loop when a new quarter has been reached.
 * @param init If we are intializing a company. If true, it will forcefully update the goals.
 * @return Returns if there was an update in a quarterly objective.
 */
function Main::EndOfQuarter(init)
{
	local change = init;
	//Check quarterly objectives (excluding top company)
	for(local i = 0; i < ObjIdx.NUM_OBJ; i++){
		//bank balance isn't quarterly, so skip it
		//also skip non-active objectives
		if(i == ObjIdx.BANK || !_Goals.IsObjActive(i)) continue;
		//update the value for the objective
		if(UpdateValue(i, init)){
			//if it was changed, mark it as such
			change = true;
		}
	}
	//return if there was a change in the value for any quarterly objective
	return change;
}

/**
 * Check for failures due to time constraints
 *
 * Called by our main loop when a new year has been reached.
 * @param init If we are intializing a company. If true, it will forcefully update the goals.
 */
function Main::EndOfYear(init)
{
	////check for goals with time limits
	for(local i = 0; i < ObjIdx.NUM_OBJ; i++){
		//if the objective isn't active then skip it
		if(!_Goals.IsObjActive(i)) continue;
		local within = _Goals.TimeLimit(i);
		//if there's no time limit, if the objective has already expired (granted we are not initializing a company,
		//or if we have not reached the time limit, then there is no way to fail, so skip this objective
		if(within == 0 || (_expired_objs[i] && !init) || GSDate.GetYear(GSDate.GetCurrentDate()) < _start_year + within) continue;
		//since we have reached the time limit, mark this objective as expired
		_expired_objs[i] = true;
		//for every company
		foreach(company_id, goal_tbl in _company_data){
			//if they have already completed the goal, achieved victory, or failed, then skip this company (for this objective at least)
			if(GSGoal.IsCompleted(goal_tbl.indiv[i]) || goal_tbl.victory_cond != VictoryState.NONE) continue;
			//get the new/latest values for this objective
			this.UpdateValue(i, init);
			//mark the company as failing
			goal_tbl.victory_cond = VictoryState.FAILED;
			//tell the company that they have failed due to time constraints
			GSNews.Create(GSNews.NT_GENERAL, GSText(GSText.VIC_FAIL_TIME, i), company_id, GSNews.NR_NONE, company_id);
			//set their goal text color to red
			this.UpdateGoalsColor(company_id);
		}
	}
}

/**
 * Create a table for the save game. This method is called by OpenTTD when an (auto)-save occurs.
 * The retured table can only contain nested tables, arrays of integers,
 * strings, null values, and booleans. Class instances and
 * floating point values cannot be stored by OpenTTD.
 * @return Returns a table with all script data that needs to be saved and tracked per save game
 */
function Main::Save()
{
	////this.Log("Saving data to savegame");

	// In case (auto-)save happens before we have initialized all data,
	// save the raw _loaded_data if available or an empty table.
	if (!this._init_done)
		return this._loaded_data != null ? this._loaded_data : {};
	
	//return (i.e. save) a table containing all the data that needs to be tracked and kept for the savegame
	return { 
		company_data=_company_data,
		start_year=_start_year,
		objs=_objs,
		story_id=_story_id,
		top_rating=_top_rating,
		expired_objs=_expired_objs,
		victories=_victories,
		global_goals = _global_goals,
		story_state = _story_state
	};
}

/**
 * Load any saved data from the savegame. When a game is loaded, 
 *  OpenTTD will call this method and pass the table that was sent to OpenTTD in Save().
 * @param version The version of the script that the data was saved with (passed by OpenTTD).
 * @param tbl The table that was saved with the savegame (passed by OpenTTD).
 */
function Main::Load(version, tbl)
{
	Util.Log("Loading data from savegame made with version " + version + " of the game script");

	// Store a copy of the table from the save game
	// but do not process the loaded data yet. Wait with that to Init
	// so that OpenTTD doesn't kick us for taking too long to load.
	this._loaded_data = {}
	//copy over the saved table to our global table
   	foreach(key, val in tbl) 
		this._loaded_data.rawset(key, val);

	//mark which script version the savegame was saved with
	this._loaded_from_version = version;
}

/**
 * Update all companys' value and local for an objective and assign them ranks relative to other companies.
 * Does not actually update a company's value if the value has not changed from last cycle.
 * @param tbl The index of the objective to update.
 * @param init If we are intializing a company(s). If true, it will forcefully update the values.
 * @return Returns if any of a company's data has changed
 */
function Main::UpdateValue(obj_idx, init){
	local ret = false;
	//reset the ranking order, objective completions, and highest rating for all companies for this objective
	_rankings_order[obj_idx] = array(0);
	_completions[obj_idx] = array(0);
	local obj_rank_order = _rankings_order[obj_idx];
	if(obj_idx == ObjIdx.TOP) _top_rating = 0;
	//for each company
	foreach(company_id, goal_tbl in _company_data){
		//if this company has completed the goal and hasn't failed don't update its value
		//top performer is the exception because the goal amount changes
		if(GSGoal.IsCompleted(goal_tbl.indiv[obj_idx]) && obj_idx != ObjIdx.TOP && goal_tbl.victory_cond != VictoryState.FAILED) {
			////Util.Log("Objective #" + obj_idx + " is already complete for company #" + company_id );
			//mark the objective as completed for this company
			_completions[obj_idx].append(company_id);
			//mark that a change has occured
			ret = true;
			//skip this company
			continue; 
		}
		//if they have not failed nor achieved victory already
		if(goal_tbl.victory_cond == VictoryState.NONE){
			//get the value from the game
			local new_value = this.GetValue(obj_idx, company_id);
			//manually set the value for rating if the game value is 0 and its the first run
			if(init && new_value == 0 && (obj_idx == ObjIdx.RATING || obj_idx == ObjIdx.TOP)) {
				//manually calculate the current rating if we're in the first quarter [50 - (2 * <loan steps>)]
				//if there's more than 20 loan steps, rating gets +1 for money
				new_value = 50 - ((Util.GetLoan(company_id) / GSCompany.GetLoanInterval()) * 2);
				////Util.Log("Loan amount: " + Util.GetLoan(company_id));
				if(new_value < 10) new_value++; 
	
			}
			//determine if the top/highest rating needs to be changed
			local update_top = (obj_idx == ObjIdx.TOP && new_value > _top_rating);
			//if the company's value for this objective has changed, if we're initializing a company,
			//or if we need to update the top rating
			if(goal_tbl.amt[obj_idx] != new_value || init || update_top){
				//udpate the company's value to the most recent one
				goal_tbl.amt[obj_idx] = new_value;
				//update top company (i.e. the goal amount for top performer)
				if(update_top)
					_top_rating = new_value;
				//signify that a change was made
				ret = true;
				////Util.Log("Change detected: objective " + obj_idx + " is now " + new_value + " for company #" + company_id);
				//update the local goal for the company
				_Goals.UpdateLocalGoal(company_id, obj_idx, _top_rating);
			}
		}
		local rank_idx = 0;
		//iterate through all the companies in the rankings
		for(local i = 0; i < obj_rank_order.len(); i++){
			//If the currennt company's value for the current objective is greater than 
			//a company in the rankings table, we've found our ranking index
			local other = _company_data[obj_rank_order[i]].amt[obj_idx];
			if(goal_tbl.amt[obj_idx] >= other) 
				break;
			//otherwise increment the ranking index
			rank_idx++;
		}
		//insert the company into the ranking array based on the index determined previously
		obj_rank_order.insert(rank_idx, company_id);
		////Util.Log("Company #" + company_id + " is now rank " + (rank_idx + 1) + " out of " + _rankings_order[obj_idx].len() + " for objective #" + obj_idx);
	}
	//create an array to store the values of previously checked company
	local amts=array(0);
	//assign the rankings to each company's rankings data
	for(local i = 0; i < obj_rank_order.len(); i++){
		//the obj_rank_order array contains company ids in the order of which they are ranked
		//so the companies are assigned rankings by taking the index of the company id
		local company_id = obj_rank_order[i];
		local true_rank = i;
		//for each value thats been checked
		for(local j = 0; j < amts.len(); j++){
			//if this company's value is the same as a previous value
			if(_company_data[company_id].amt[obj_idx] == amts[j]){
				//then the company is tied, and their true rank is the same as the company with the same value
				true_rank = j;
				break;
			}
		}
		//store the checked company's value in the array
		amts.append(_company_data[company_id].amt[obj_idx]);
		//set the company's place to their true rank, after compelted companies.
		_company_data[company_id].rankings[obj_idx] = _completions[obj_idx].len() + true_rank + 1;
	}
	//for each company who's completed the goal (iterated in reverse order since the completions is reversed)
	for(local i = _completions[obj_idx].len() - 1; i >=0 ; i--)		
		//add them to the beginning of the rankings
		obj_rank_order.insert(0, _completions[obj_idx][i]);
	//return if a value was actually updated
	return ret;
}

/**
 * Update all companys' goal text color. It essentially just forces the goals to update.
 * @param company_id The id of the company to update goal text for.
 */
function Main::UpdateGoalsColor(company_id){
	//update the goal goals for every company
	_Goals.UpdateGlobalGoals(_rankings_order, _top_rating);
	//update the local goal for each objective of the company (if that objective is active)
	for(local i = 0; i < ObjIdx.NUM_OBJ; i++)
		if(_Goals.IsObjActive(i))
			_Goals.UpdateLocalGoal(company_id, i, _top_rating);
}

/**
 * Get the most recent value from the game for a specific objective and company
 * @param obj_idx The index of the objective to get the value for.
 * @param company_id The id of the company to get the value for.
 */
function Main::GetValue(obj_idx, company_id){
	local quarter = GSCompany.CURRENT_QUARTER;
	//determine the value from the game to return based on the objective index
	switch(obj_idx){
		case ObjIdx.COMPANY:
			return GSCompany.GetQuarterlyCompanyValue(company_id, quarter);
			break;
		case ObjIdx.INCOME:
			return GSCompany.GetQuarterlyIncome(company_id, quarter);
			break;
		case ObjIdx.TOP:
		case ObjIdx.RATING:
			return GSCompany.GetQuarterlyPerformanceRating(company_id, quarter + 1);
			break;
		case ObjIdx.CARGO:
			return GSCompany.GetQuarterlyCargoDelivered(company_id, quarter);
			break;
		case ObjIdx.BANK:
			return GSCompany.GetBankBalance(company_id) - Util.GetLoan(company_id);
			break;
	}
}






