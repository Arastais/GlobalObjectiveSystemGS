# Global Objective System Game Script
Global Objective System is a Game Script (a type of add-on) for the game [OpenTTD](https://github.com/OpenTTD/OpenTTD "OpenTTD on GitHub"). It gives players a way to create a global challenge/main objective system for all companies in the game to achieve and compete against each other for. It is fully customizable by allowing players to add or remove different challenges to the objective and change goal amounts for each challenge through the Game Script configuration in-game. It tries to mimic and is inspired heavily by the challenge system in Chris Sawyer's Locomotion and RollerCoaster Tycoon 2, while also adding features to it.
![goals window](https://user-images.githubusercontent.com/1361714/192644791-af2955d1-4e32-4f70-828c-d65c3bd9906a.png)
Zuu's [Minimal GS](http://www.tt-forums.net/viewtopic.php?f=65&t=62163) was used to create this script. Although much of the boilerplate template has been changed or built upon, there are still some remenents of his work in the script. OpenTTD community user [dP](https://github.com/ldpl) gave the inspiration for the design of the goals window.

If you find any bugs or issues with the script, feel free to open an issue on GitHub in this repo. If you would like to contribute, you can look at the To Do list at the bottom of this readme; I have marked how difficult each item would be to do in terms of time and effort.
# Recommended Objectives
Here are some objectives that I personally found enjoyable during testing and playing:
- 100 Year Challenge: Achieve a high (900+) performance rating within 100 years (starting around 1940) and be the top performer. Good on a large map with many competing players/ai
- Making It Big: Achieve a large ($4M+) company value within maybe 50 years, and be the top performer. Any map size or amount of competition is good for this one.
- First to 20M: Have 20M in your bank within 30 years. Best with less players (less than 4)

# Quirks & Intricacies
## Intended Mechanics
- If a company fails or achieves victory (by compelting the objective) they are "taken out" of the competition: their progress will no longer be tracked and they will not be considered when determining the top performace rated player
- All progress (except for amount of money in the bank) is updated quartlerly; This is because OpenTTD only tracks those on a quarterly basis
- The script updates everything else approximately every 5 in-game days
- If a company achieves victory, their ranking text in the global goals window will turn green
- If a company fails, their text for all goals will turn green
- If a certain challenge/goal has a time constraints (i.e. must completed before a certain year), then once that year occurs in the game, all companies who have not already achieved victory will immediately fail
## In-game Parameter Configuration
- Goals with money amounts (i.e. company value, money in bank, etc.) are in british pound-sterling in the configuration screen. This is because OpenTTD converts the numbers to "Money", which means the values are converted from the base (which is pounds) into your currency set in the game options. This means putting in 100,000 as a config parameter will make it show as $200,000 USD in the game.
- There are intentional spaces between each challenge to seperate them and make the configuration window easier to read. It may look like a bug since there are arrows next to the empty line, but it was the only was to allow for empty lines within this window.
## Shortcomings & Possible Bugs
1. There was a bug that if at least one company acchieved victory, then if any company fails after that, all failing companies get a completion percentage equal to the maximum negative 64-bit integer (after being converted from a +infinty float). The easiest workaround was to make it so that any calculated percentage below 0 is just shown as 0%, but this is more of a "duct tape" fix, as I was not able to find the exact cause of this.
2. The code is quite messy and honestly porbably not optimized well as my goal was to do it as fast as possible without any major bugs. I tried to compensate this by commenting everything and giving my remarks (see section below)
3. I was not able to get Enums to be visible in the same way they would be in C++. Putting enums in one file does not make them visible to another it seems, and I did not want to put them in a class.
4. As mentioned earlier, when configuring the script, the amounts must be in pound sterling and not the currency the game is currently set to. I don't know if there's a way to convert the parameter to local currency first within the source code (rather than it being converted from pounds to whatever currency), since it did not seem like there was a way to get the game option of which currency is in the game options. The API lets the game script access acutal settings, but it did not say anything about accessing game options (which are seperate).
## Programming Remarks
- All of the code has been extensively documented and commented, and is doxygen compatible
- The term "objective" in the source code refers to each individual goal/challenge within the goal window, while everywhere else it refers to the entire set of challenges (i.e. the set of goals that make up the "objective" of the game)

# To Do
1. Create an objective for delivering a *specific* cargo, not just any cargo (requires tracking cargo deliveries manually) [Medium]
2. Create an objective for lifetime cargo [Easy]
3. Create an objective that combines the previous two [Medium]
4. Show an actual list of players in multiplayer (requires creating fake vehicle groups, as raw strings don't work; there's a commented section in the source code for this with raw strings) [Hard]
5. Make the in-game configuration for the script use the player-set currency instead of always pound sterling (see shortcomings #4 for clarification) [Hard (if it's even possible)]
6. Make a toggable config option to show the story page when the game starts (right now it always does and players don't get a choice) [Easy]
7. Annnounce in the status bar (like how subsidiaries do) when an objective has expired due to time constraints [Easy]
8. Add a configuration option to change the update interval of the script, not just always 5 days. [Easy]
9. Have an indication in the goals window of when the next quarterly update is [Easy]
10. Custom objective names for a given set of goals [Medium]
