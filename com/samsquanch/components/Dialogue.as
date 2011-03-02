package com.samsquanch.components {
	import com.adobe.serialization.json.JSON;
	import com.samsquanchgames.components.*;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import net.flashpunk.FP;

	/**
	 * A dialogue/conversation manager for in-game dialogues that can branch
	 * or lead towards specific goals. Dialogues can include multiple goals
	 * and multiple characters.
	 * 
	 * Also uses the I18n package to make dialogue elements translatable, and
	 * to define custom tags in the dialogue text to be replaced with dynamic
	 * values. For example, the tag {name} might be used to be replaced with
	 * the player's name.
	 * 
	 * Each piece of dialogue can have up to four responses, called options.
	 * Each option has a corresponding "goto" with the next point in the
	 * conversation tree, and other actions to be taken based on the player's
	 * choices. A dialogue for a character looks like this:
	 * 
	 * "joe": [
	 *     {
	 *         "num": 0, // this is how you refer to each object
	 *         "text": "Hello {name}", // speech from the character
	 *         "graphic": "", // an optional graphic to display
	 *         "opt_a": "Hello", // the first option text
	 *         "goto_a": { // the goto for this option
	 *             "joe": 1 // move to object 1 for joe
	 *         }
	 *     },
	 *     {
	 *         "num": 1,
	 *         "text": "Nice weather today, eh?",
	 *         "graphic": "",
	 *         "opt_a": "Yup",
	 *         "goto_a": {
	 *             "joe": 0, // loop back to object 0
	 *             "goal": 0, // add to goal 0
	 *             "show": "Well, have a good one." // an optional follow-up message
	 *         },
	 *         "opt_b": "Whatever",
	 *         "goto_b": {
	 *             "follow": 2, // continue joe's conversation immediately with object 2
	 *             "sub": 0, // subtract from goal 0
	 *         }
	 *     },
	 *     {
	 *         "num": 2,
	 *         "text": "Chill out, dude!",
	 *         "graphic": "",
	 *         "opt_a": "Sorry, I'm just tired.",
	 *         "goto_a": {
	 *             "joe": 0,
	 *             "show": "Ah, no worries."
	 *         }
	 *     }
	 * ]
	 * 
	 * You can specify other characters in any goto, allowing you to unlock
	 * conversations with other characters than the current one, such as things
	 * like "Joe told me you like board games..."
	 * 
	 * The goto can also point you back to previous objects, creating loops or
	 * unlocking loops in conversation depending on the player's choices.
	 * 
	 * Here's an explanation of each element:
	 * 
	 * num - How you refer to each dialogue object for each character. Each dialogue
	 *     starts at 0 for each character.
	 * 
	 * text - Some text to be spoken by the character.
	 * 
	 * graphic - An optional graphic to add to the text.
	 * 
	 * opt_a, opt_b, opt_c, opt_d - The possible responses you can make at this point.
	 * 
	 * goto_a, goto_b, etc. - Where to go in the dialogue for each response, as well as
	 *     other actions such as achieving goals.
	 * 
	 * goto_* / {character} - Move to this dialogue object for the specified character.
	 * 
	 * goto_* / show - Show a quick response or feedback based on their choice.
	 * 
	 * goto_* / follow - Immediately switch to the next dialogue object to continue the
	 *     current conversation.
	 * 
	 * goto_* / goal - Add 1 to the specified goal.
	 * 
	 * goto_* / sub - Subtract 1 from the specified goal.
	 * 
	 * Requires the JSON package from Adobe, available here:
	 *
	 * https://github.com/mikechambers/as3corelib
	 * 
	 * Usage:
	 * 
	 * 1. Define the characters you can talk to:
	 * 
	 * Dialogue.addCharacter ('joe');
	 * Dialogue.addCharacter ('steve');
	 * 
	 * 2. Import your conversations:
	 * 
	 * Dialogue.importConversation ('joe', '../assets/conversations/joe.json');
	 * Dialogue.importConversation ('steve', '../assets/conversations/steve.json');
	 * 
	 * 3. Integrate into your gameplay:
	 * 
	 * // character was selected
	 * Dialogue.talkingTo = character.name;
	 * var show:String = Dialogue.getText ();
	 * var opts:Array = Dialogue.getOptions ();
	 * 
	 * // your gui code here
	 * var label:Label = new Label(null);
	 * label.text = show;
	 * // etc.
	 * 
	 * // button for option 1 was chosen
	 * var res:Object = Dialogue.doChoice (0);
	 * if (res.hasOwnProperty ('show')) {
	 *     // show a response message
	 * } else if (res.hasOwnProperty ('follow')) {
	 *     // show follow-up dialogue
	 * }
	 * 
	 * // check on the goals
	 * if (Dialogue.goals[0] == 10) {
	 *     // goal reached (number is arbitrary :)
	 * }
	 */
	public class Dialogue {
		/**
		 * The character the player is currently in conversation with.
		 */
		public static var talkingTo:String = '';
		
		/**
		 * Tracks a series of goals to be achieved through conversations.
		 */
		public static var goals:Array = [0, 0, 0, 0, 0];
		
		/**
		 * The state of conversation for each character.
		 */
		public static var state:Object = {};
		
		/**
		 * Temp var for import success handler.
		 */
		public static var tmpChar:String = '';
		
		/**
		 * Conversations list, defined via importConversation().
		 */
		public static var conversations:Object = {};

		/**
		 * Add a character to talk to.
		 */
		public static function addCharacter (name:String):void {
			state[name] = 0;
			conversations[name] = [];
		}

		/**
		 * Import a conversation from a JSON-formatted file. Each file should
		 * contain an array of conversation objects for a specific character.
		 * See above for formatting examples and explanations.
		 */
		public static function importConversation (forChar:String, file:String):void {
			tmpChar = forChar;
			var request:URLRequest = new URLRequest (file);
			var loader:URLLoader = new URLLoader ();
			loader.addEventListener (Event.COMPLETE, importComplete);
			loader.load (request);
		}
		
		/**
		 * importConversation() complete event handler.
		 */
		private static function importComplete(event:Event):void {
			var loader:URLLoader = URLLoader (event.target);
			conversations[tmpChar] = (JSON.decode (loader.data) as Array);
		}

		/**
		 * Get the text for the current conversation.
		 */
		public static function getText ():String {
			var num:Number = state[talkingTo];
			return I18n.tr (conversations[talkingTo][num].text);
		}

		/**
		 * Get the response options for the current conversation.
		 */
		public static function getOptions ():Array {
			var options:Array = [];
			var num:Number = state[talkingTo];
			options.push (conversations[talkingTo][num].opt_a);
			if (conversations[talkingTo][num].hasOwnProperty ('opt_b')) {
				options.push (conversations[talkingTo][num].opt_b);
			}
			if (conversations[talkingTo][num].hasOwnProperty ('opt_c')) {
				options.push (conversations[talkingTo][num].opt_c);
			}
			if (conversations[talkingTo][num].hasOwnProperty ('opt_d')) {
				options.push (conversations[talkingTo][num].opt_d);
			}
			return options;
		}

		/**
		 * Make a choice in the current conversation.
		 */
		public static function doChoice (c:Number):Object {
			var num:Number = state[talkingTo];
			var actions:Object;

			if (c == 0) {
				actions = conversations[talkingTo][num].goto_a;
			} else if (c == 1) {
				actions = conversations[talkingTo][num].goto_b;
			} else if (c == 2) {
				actions = conversations[talkingTo][num].goto_c;
			} else if (c == 3) {
				actions = conversations[talkingTo][num].goto_d;
			}

			// loop through characters and move the conversation
			// forward
			for (var s:String in state) {
				if (actions.hasOwnProperty (s)) {
					state[s] = actions[s];
				}
			}

			// add/subtract from goals
			if (actions.hasOwnProperty ('goal')) {
				goals[actions.goal]++;
			}
			if (actions.hasOwnProperty ('sub')) {
				goals[actions.sub]--;
			}
			
			// return a response message, if available
			if (actions.hasOwnProperty ('show') || actions.hasOwnProperty ('follow')) {
				return actions;
			}
			return {};
		}
	}
}