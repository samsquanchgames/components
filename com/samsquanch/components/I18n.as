package com.samsquanch.components {
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	/**
	 * Basic class for translating text in-game. Requires the JSON
	 * package from Adobe, available here:
	 *
	 * https://github.com/mikechambers/as3corelib
	 *
	 * Usage:
	 *
	 * 1. Import your translations: I18n.importTranslations ('../assets/translations/fr.json').
	 *
	 * 2. Use I18n.setLang ('fr') to set the language to translate to.
	 *
	 * 3. Use I18n.tr('original text') to return a translated string.
	 *
	 * 4. Use I18n.replacements = {'name': 'Player Name'} to define a
	 *    list of keys to be automatically replaced during calls to
	 *    I18n.tr().
	 */
	public class I18n {
		/**
		 * List of translations, to be loaded via importTranslations('file.json').
		 * The default value provides an example of how a translation object
		 * should appear in the JSON files.
		 */
		private static var translations:Object = {
			'fr': {
				'Hello {name}': 'Bonjour {name}'
			}
		};
		
		/**
		 * Default language.
		 */
		private static var default_lang:String = 'en';
		
		/**
		 * Current language.
		 */
		private static var lang:String = 'en';
		
		/**
		 * Temp var for import success handler.
		 */
		private static var tmpLang:String = 'en';
		
		/**
		 * List of strings to replace in translations when
		 * {key_name} tags are encountered. Defined via
		 * setReplacements({'key': 'value'}).
		 */
		private static var replacements:Object = {
			'name': 'Player Name'
		};
		
		/**
		 * Set the current language.
		 */
		public static function setLang(new_lang:String = null):String {
			lang = (new_lang) ? new_lang : default_lang;
			return lang;
		}

		/**
		 * Define the list of replacements.
		 */
		public static function setReplacements (rep:Object):void {
			replacements = rep;
		}
		
		/**
		 * Import translation strings from a JSON-formatted file.
		 */
		public static function importTranslations(forLang:String, filename:String):void {
			tmpLang = forLang;
			var request:URLRequest = new URLRequest (filename);
			var loader:URLLoader = new URLLoader ();
			loader.addEventListener (Event.COMPLETE, importComplete);
			loader.load (request);
		}

		/**
		 * importTranslations() complete event handler.
		 */
		private static function importComplete(event:Event):void {
			var loader:URLLoader = URLLoader (event.target);
			translations[tmpLang] = JSON.decode (loader.data);
		}
		
		/**
		 * Return a translated string.
		 */
		public static function tr (str:String):String {
			var res:String = '';
			if (lang != default_lang && translations[lang][str] != null) {
				res = translations[lang][str];
			} else {
				res = str;
			}
			
			// do replacements
			for (var n:String in replacements) {
				res = res.replace ('{' + n + '}', replacements[n]);
			}

			return res;
		}
	}
}