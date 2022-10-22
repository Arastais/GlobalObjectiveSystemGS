This script gives players a way to create a global challenge/main objective system for all companies in the game to achieve and compete against each other for. It is fully customizable by allowing players to add or remove different challenges to the objective and change goal amounts for each challenge through the Game Script configuration in-game. It tries to mimic and is inspired heavily by the challenge system in Chris Sawyer's Locomotion and RollerCoaster Tycoon 2, while also adding features to it.

Zuu's Minimal GS was used to create this script. Although much of the boilerplate template has been changed or built upon, there are still some remenents of his work in the script.

If you find any bugs or issues, want to know more about this script, or would like to contribute, please visit the website (i.e. the GitHub repo).

AS a reconommendation, here are some objectives that I personally found enjoyable during testing and playing:
- 100 Year Challenge: Achieve a high (900+) performance rating within 100 years (starting around 1940) and be the top performer. Good on a large map with many competing players/ai
- Making It Big: Achieve a large ($4M+) company value within maybe 50 years, and be the top performer. Any map size or amount of competition is good for this one.
- First to 20M: Have 20M in your bank within 30 years. Best with less players (less than 4)

Intended Mechanics:
- You are allowed to change the GS parameters while in a game, but they won't take affect in exising games, only new ones. You are allowed to change them so that you can modify and intiliaze the game script in existing scenarios (.scn files). This means that once you start a new game with the script, the parameters for that specific game and associated saves will not have any effect.
- If a company fails or achieves victory (by compelting the objective) they are "taken out" of the competition: their progress will no longer be tracked and they will not be considered when determining the top performace rated player
- All progress (except for amount of money in the bank) is updated quartlerly; This is because OpenTTD only tracks those on a quarterly basis
- The script updates everything else approximately every 5 in-game days
- If a company achieves victory, their ranking text in the global goals window will turn green
- If a company fails, their text for all goals will turn green
- If a certain challenge/goal has a time constraints (i.e. must completed before a certain year), then once that year occurs in the game, all companies who have not already achieved victory will immediately fail

Parameter Configuration:
- To turn an objective on, change it's value from 0. 0 in the configuration means it's off.
- There are intentional spaces between each challenge to seperate them and make the configuration window easier to read. It may look like a bug since there are arrows next to the empty line, but it was the only was to allow for empty lines within this window.
- Goals with money amounts (i.e. company value, money in bank, etc.) are in british pound-sterling in the configuration screen. This is because OpenTTD converts the numbers to "Money", which means the values are converted from the base (which is pounds) into your currency set in the game options. This means putting in 100,000 as a config parameter will make it show as $200,000 USD in the game.
