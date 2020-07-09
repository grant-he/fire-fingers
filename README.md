# Fire Fingers
*A speed-focused typing game for competitors on the go.*

#### Details
Akin to the online browser-based typing game [*TypeRacer*](https://play.typeracer.com/). The main feature of the game is that players are given a matching prompt which they must correctly type as fast as they can. The player who completes the prompt fastest is considered the winner. As you race, your words per minute will be recorded, allowing you to track your typing speed over time.

Available on iOS 13.5+.

#### Special Instructions
- Open the file Fire Fingers.xcworkspace (as opposed to the file Fire Fingers.xcodeprog).
- Use an iPhone 11 Pro Max for the optimal experience.
- Application only works for portrait mode.
- To test lobbies/games with multiple players, build and run the application for different simulators simultaneously.
- Note that haptic feedback does not work for simulators.
- Enjoy! 🏎️ 🏎️

#### Project Dependencies
- Xcode 11.5
- Swift 5
- Firebase (Auth & Firestore)
- MessageKit

#### Team
Made by Grant He ([@grant-he](https://github.com/grant-he)) & Garrett Egan ([@garrettwegan](https://github.com/garrettwegan)) in the Summer of 2020.

#### Features
| Feature | Description | Approximate Contribution |
| ----------- | ----------- | ----------- |
| Login Screen | Use email and password to login/create a user, or continue as guest. | 90% Grant, 10% Garrett  |
| Host Lobby Screen | Set game options and create lobby. | 50% Grant, 50% Garrett |
| Join Lobby | Ready up and chat with other players. | 60% Garrett, 40% Grant |
| Chat Lobby | Message other players through chat lobbies. | 100% Garrett |
| User Settings | Store/retrieve current user settings. | 50% Grant, 50% Garrett |
| Replay Game | Allow players to replay with the same lobby. | 100% Garrett |
| Game Options | Instant death, earthquakes (haptics), emoji prompts. | 80% Grant, 20% Garrett |
| Prompts | Handle player input and progress. | 80% Grant, 20% Garrett |
| Data Modeling | Use Firestore to save game results, lobbies, and prompts. | 80% Garrett, 20% Grant |
| Leaderboards | Display current and other players' ranking and statistics.  | 100% Garrett |
| Sounds | Play audio effects at set volume. | 100% Grant |
| Icons | Customize user icon for games. | 75% Grant, 25% Garrett |
| Other UI/UX | Miscellaneous stuff | 70% Grant, 30% Garrett |

#### License
Fire Fingers is released under the [MIT License](https://github.com/grant-he/fire-fingers/blob/master/LICENSE).
