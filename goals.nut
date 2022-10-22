require("util.nut");

/**
 * Class for handling the updating and managing of goals
`*/
class Goals {
	_company_data = {}; ///< the company data table passed from the main class
	_global_goals = array(0, null); ///< an array continaing the ids of the global goals
	_objs = array(0); ///< objective data grom the main class
	_obj_titles = array(0); ///< GSText for the titles of each objective
	_story_id = null; ///< the id of the story page passed from the main class
	///_top_rating = null;
	static function CreateStoryPage();
	constructor(company_data, global_goals, objs, start_year, story_id){
		_company_data = company_data;
		_global_goals = global_goals;
		_objs = objs;
		_obj_titles = this.CreateObjTitles(start_year);
		_story_id = story_id;
		///_top_rating = top_rating;
	}
}


enum ObjParam {
	VALUE,
	WITHIN,
	KEY,
	PROG_KEY
}
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

/**
 * Update the local goal for a given company and objective
 * @param obj_idx The index of the objective to update the goal for.
 * @param company_id The id of the company to update the goal for.
 * @param top_rating The value of the highest performance rating
 */
function Goals::UpdateLocalGoal(company_id, obj_idx, top_rating){
	this.UpdateGoal(company_id, obj_idx, false, top_rating);
}

/**
 * Update the global goals (for all companies and objectives)
 * @param rank_order An array containing the order of which the comapnies are ranked
 * @param top_rating The value of the highest performance rating
 */
function Goals::UpdateGlobalGoals(rank_order, top_rating){
	////Util.Log("Updating global goals...");
	//reset/clear the goal list
	if(_global_goals.len() > 0){
		//remove the goals from the goal window
		foreach(goal_id in _global_goals)
			GSGoal.Remove(goal_id);
		//clear the global goal array
		_global_goals.clear();
	}
	/* Construct global goals */
	//add the "Objective:" title to the goal window
	_global_goals.append(GSGoal.New(GSCompany.COMPANY_INVALID, GSText(GSText.GOAL_TITLE), GSGoal.GT_STORY_PAGE, _story_id));
	//for each objective
	for(local i = 0; i < ObjIdx.NUM_OBJ; i++){
		//if there's no title for it (because it's not active) skip it
		if(_obj_titles[i] == null) continue;
		//add the title for the goal to the goal window, and add it to the global goal array
		_global_goals.append(GSGoal.New(GSCompany.COMPANY_INVALID, _obj_titles[i], GSGoal.GT_STORY_PAGE, _story_id));
		////Util.Log(rank_order[i].len() + " companies with rankings for objective " + i);
		//for each company (going in order of ranking)
		foreach(company_id in rank_order[i]){
			//create the goal for this company and objective
			local global_goal_id = this.UpdateGoal(company_id, i, true, top_rating);
			//add its id to the global goal array
			_global_goals.append(global_goal_id);
			//set the global goal for the company and for this objective to the goal we just made
			_company_data[company_id].global[i] = global_goal_id;
		}
	}
	//Add an anding spacer to the global goal window, and add it to the global goal array
	_global_goals.append(GSGoal.New(GSCompany.COMPANY_INVALID, "", GSGoal.GT_NONE, 0));
}

/**
 * Update the local goal (and its text) for a given company and objective
 *
 * The local goals for a company must first be created by calling 
 * Goals::CreateLocalGoals(company_id) at least once before
 * @param obj_idx The index of the objective to update the goal for
 * @param company_id The id of the company to update the goal for
 * @param global If a global or local/individual goal should be updated
 * @param top_rating The value of the highest performance rating
 */
function Goals::UpdateGoal(company_id, obj_idx, global, top_rating){
	local goal_tbl = _company_data[company_id];
	local complete = false;
	local amt = goal_tbl.amt[obj_idx];
	local goal_amt = null;
	//if top performer objective, then set the goal amount to the top amount, not the configuration parameter
	if(obj_idx == ObjIdx.TOP) goal_amt = top_rating;
	//otherwise set it to the config parameter
	else goal_amt = _objs[obj_idx][ObjParam.VALUE];
	//make the denominator a float
	local goal_amt_float = goal_amt * 1.0; 
	//calculate the completion percentage
	//if it's the top performer objective, and top rating is 0, just make the percentage 100%
	local percentage = (top_rating == 0 && obj_idx = ObjIdx.TOP) ? 100 : (amt/goal_amt_float) * 100;
	//by default, the progress text is yellow
	local color_key = GSText.GOAL_INPROG; 
	//If their objective is marked as failed, set the text red 
	//and set the goal as completed (so it will not longer be tracked)
	if(goal_tbl.victory_cond == VictoryState.FAILED){
		//set the text red
		color_key = GSText.GOAL_FAIL;
		//mark the goal as completed so the script won't modify it anymore
		complete = true; 
	}
	//if the objective is completed, set it as such so it will no longer be trakced
	else if(percentage >= 100) { 
		//set the text green
		color_key = GSText.GOAL_DONE;
		//make the percentage text "100%"
		percentage = 100; 
		//mark the goal as completed, unless it's top performer
		if(obj_idx != ObjIdx.TOP) complete = true; 
	}
	//NOTE: This is here to fix a bug where if all companies fail or achieve victory, the percentage becomes +infinity
	//Most likely due to a float divison of x/0.0, where x is a positive number
	//Thus when percentage is converted to an integer, it becomes -LONG_MAX (largest negative 64-bit signed integer)
	//I was not able to find the exact cause of this, and did this as a workaround
	if(percentage.tointeger() < 0) percentage = 0;
	////Util.Log("Percentage for company #" + company_id + " for objective #" + obj_idx + " is " + percentage + "% (" + percentage.tointeger() +"%) [top rating is " + top_rating + "]");
	//get the ranking array of this company for this objective
	local rank = goal_tbl.rankings[obj_idx];
	//if its somehow null, show 0 as a fallback
	if(rank == null) rank = 0;
	////Util.Log("Rank for company #" + company_id + " is " + rank);
	//get/create the player list if its a global goal
	local player_list = "";
	/* This doesnt work because raw strings can't be used for the GSText parameter
	if(global){
		local client_list = GSClientList_Company(company_id);
		Util.Log("Client list for company #" + company_id + " has " + client_list.Count() + " players");
		local player_item = client_list.Begin();
		while(!client_list.IsEnd()){
			if(player_list != "") player_list += ", ";
			player_list += GSClient.GetName(GSList.GetValue(player_item));
			Util.Log("Found client #" + GSList.GetValue(player_item) + " in company #" + company_id);
			player_item = client_list.Next();
		}
	}*/
	//if it's a global goal in a single player game, and this company is the player
	if(global && !GSGame.IsMultiplayer() && company_id == 0)
		//Add a "(You)" to the company name
		player_list = GSText(GSText.GOAL_SELF_CLIENT);
	//get the goal id (or create a new goal if its a global one)
	local goal_id = global ? 
		GSGoal.New(GSCompany.COMPANY_INVALID, GSText(goal_tbl.victory_cond == VictoryState.ACHIEVED ? GSText.GOAL_GLOBAL_DONE : GSText.GOAL_GLOBAL, rank, GSText(color_key, GSText(GSText.GOAL_PERCENT, percentage.tointeger())), company_id, player_list), GSGoal.GT_COMPANY, company_id) : 
		goal_tbl.indiv[obj_idx];
	//set the progress, with the last parameter (the goal percent completion) depending on if global or not
	GSGoal.SetProgress(goal_id, GSText(color_key, GSText(_objs[obj_idx][ObjParam.PROG_KEY], goal_tbl.amt[obj_idx], goal_amt, global ? "" : GSText(GSText.GOAL_PERCENT, percentage.tointeger()))));
	//set the goal as completed if it's been marked as such
	GSGoal.SetCompleted(goal_id, complete);
	return goal_id;
}

/**
 * Create the body text for the story page.
 *
 * Goals.CreateStoryPage() has to have been called at least once previously,
 * otherwise this function will not show the objectives and may crash the script
 */
function Goals::CreateStoryBody(){
	//create an array of texts to make the body of the storage page
	//start with the first paragraph body text
	local texts = [GSText(GSText.STORY_BODY_PRE)];
	//add every objective text/title to the story page body text
	texts.extend(_obj_titles);
	//add a spacer line
	texts.append(" ");
	//add the last paragraph body text
	texts.append(GSText(GSText.STORY_BODY_POST));
	//"publish" each lie of text in the array to the story page
	foreach(text in texts) GSStoryPage.NewElement(_story_id, GSStoryPage.SPET_TEXT, 0, text); 
}

/**
 * Creates the story page (with no text in its body)
 * @return Returns the id of the story page.
 */
function Goals::CreateStoryPage(){
	//create a story page with our story title
	return GSStoryPage.New(GSCompany.COMPANY_INVALID, GSText(GSText.STORY_TITLE));
}

/**
 * Create the titles (i.e. the text that describes the objectives) for each active objective
 *
 * This function is automatically called when a Goals class instance is constructed
 * @param start_year The start year of the game
 * @return Returns an array of objective texts
 */
function Goals::CreateObjTitles(start_year){
	//create an array for the objective titles
	local ret = array(ObjIdx.NUM_OBJ, null);
	//for each objective
	for(local i = 0 ; i < _objs.len() ; i++){
		//if the objective isn't active, skip it
		if(!this.IsObjActive(i)) continue;
		//get the goal amount for the objective (from the config parameters)
		local value = _objs[i][ObjParam.VALUE];
		//get the tie constraint of the objective (from the config parameters)
		local within_years = _objs[i][ObjParam.WITHIN];
		//create the main text instance for the objective title
		local main_text = GSText(_objs[i][ObjParam.KEY]);
		//if we're not on the top performer objective
		if(i != ObjIdx.TOP) {
			//add the goal value for the objective as a parameter for the text.
			main_text.AddParam(value);
			//if we're on the rating objective
			if(i == ObjIdx.RATING) {
				//add the title as a paramter for the text
				main_text.AddParam(Util.GetRatingTitle(value));
			}
		}
		//if there is an active time constraint (i.e. it's value isn't 0/off),
		//add the time constraint year as a parameter
		if(within_years != 0) main_text.AddParam(GSText(GSText.OBJ_YEAR, start_year + within_years))
		//otherwise leave the parameter blank
		else main_text.AddParam("");
		//add the text instance to the array of objective titles
		ret[i] = main_text;
	}
	//now that the title array is complete, return it;
	return ret;
}

/**
 * Create all local goals (i.e. creates objective titles in the goals window) for a given company (but does not update them)
 * @param company_id The id of the company to create local goals for
 */
function Goals::CreateLocalGoals(company_id){
	//Add the "Objective:" title to the local goal window
	GSGoal.New(company_id, GSText(GSText.GOAL_TITLE), GSGoal.GT_STORY_PAGE, _story_id); 
	//for each objective
	for(local i = 0; i < _objs.len(); i++)
		//if it has a title (i.e. it's an active objective
		if(_obj_titles[i] != null)
			//Create a new goal for it and assign it as that company's individual/local goal
			_company_data[company_id].indiv[i] = GSGoal.New(company_id, _obj_titles[i], GSGoal.GT_STORY_PAGE, _story_id);
	//Add an ending spacer line to the local goal window
	GSGoal.New(GSCompany.COMPANY_INVALID, "", GSGoal.GT_NONE, 0);
}

/**
 * Check if an objective is active (i.e. has been enabled by the user in the configuration parameters)
 * @param obj_idx The index of the objective to check
 * @return Returns if the objective is active
 */
function Goals::IsObjActive(obj_idx){
	return _objs[obj_idx][ObjParam.VALUE] != 0;
}

/**
 * Check the time constraint (i.e. completion within this many years) of an objective that has been set by the user in the configuration parameters
 * A value of 0 signifies that it is off and thus there are no set constraints
 * @param obj_idx The index of the objective to check
 * @return Returns the number of years the objective needs to be completed within
 */
function Goals::TimeLimit(obj_idx){
	return _objs[obj_idx][ObjParam.WITHIN];
}

