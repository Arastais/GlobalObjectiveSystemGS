/**
 * A class consiting of miscellanious utility/helper functions which are all static
 */
class Util {
	static function GetLoan(company_id);
	static function GetRankSuffix(place);
	static function GetRatingTitle(rating);
	static function Log(text);
}

/**
 * Get the current loan of a given company
 * @param company_id The id of the company
 * @return Returns the current loan of the company in GBP
 */
function Util::GetLoan(company_id){
	//set the "active" company to the passed one
	local cm = GSCompanyMode(company_id);
	//return the loan amount
	return GSCompany.GetLoanAmount();
}

/**
 * Get the suffix of a placing (e.g. "st" for 1st)
 * @param place The ranking to get the suffix for
 * @return Returns a GSText ID for the suffix text
 */
function Util::GetRankSuffix(place){
	switch(place){
		case 2:
			//if second place return "nd"
			return GSText.VIC_SUFFIX_2;
		case 3:
			//if third place return "rd"
			return GSText.VIC_SUFFIX_3;
		default:
			//first place doesn't use this function, so all other places return "th"
			return GSText.VIC_SUFFIX_N;
	}
}

/**
 * Get the title for a specific performance rating
 * @param rating The rating value to get the title for
 * @return Returns a GSText object of the title
 */
function Util::GetRatingTitle(rating){
	local title = null;
	//titles change after 2050, so get the new titles instead
	if(GSDate.GetYear(GSDate.GetCurrentDate()) >= 2050){
		if (rating >= 960) title = GSText.TITLE_TYCOON_C;
		else if(rating >= 832) title = GSText.TITLE_MOGUL;
		else if(rating >= 704) title = GSText.TITLE_MAGNATE;
		else if(rating >= 576) title = GSText.TITLE_CAPITALIST;
		else if(rating >= 448) title = GSText.TITLE_INDUSTRIALIST;
		else if(rating >= 320) title = GSText.TITLE_ENTREPRENEUR;
		else title = GSText.TITLE_BUSINESSPERSON;
	} else {
		if (rating >= 960) title = GSText.TITLE_TYCOON;
		else if(rating >= 896) title = GSText.TITLE_PRESIDENT;
		else if(rating >= 768) title = GSText.TITLE_CHAIRPERSON;
		else if(rating >= 640) title = GSText.TITLE_CHIEF_EXECUTIVE;
		else if(rating >= 512) title = GSText.TITLE_DIRECTOR;
		else if(rating >= 384) title = GSText.TITLE_ROUTE_SUPERVISOR;
		else if(rating >= 256) title = GSText.TITLE_TRANSPORT_COORDINATOR;
		else if(rating >= 128) title = GSText.TITLE_TRAFFIC_MANAGER;
		else title = GSText.TITLE_ENGINEER;
	}
	return GSText(title);
}

/**
 * Log some text in the console and gamescript debug
 * @param text The text to log
 */
function Util::Log(text){
	GSLog.Info(text);
}