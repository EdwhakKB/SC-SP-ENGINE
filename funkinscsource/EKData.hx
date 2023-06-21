/**
    This is the most spammy class ever
**/
class EKData {
    // A Animation --> PURPLE
    // B Animation --> BLUE
    // C Animation --> GREEN
    // D Animation --> RED
    // E Animation --> WHITE
    // F Animation --> YELLOW
    // G Animation --> VIOLET
    // H Animation --> DARKRED
    // I Animation --> DARKBLUE
    // J Animation --> purpleCircle
    // K Animation --> blueCircle
    // L Animation --> greenCircle
    // M Animation --> redCircle
    // N Animation --> whiteCircle
    // O Animation --> yellowCircle
    // P Animation --> violetCircle
    // Q Animation --> darkredCircle
    // R Animation --> darkblueCircle
    public static var keysShit:Map<Int, Map<String, Dynamic>> = [ // Ammount of keys = num + 1
		0 => [
                "letters" => ["white"], 
                "anims" => ["UP"], 
                "strumAnims" => ["SPACE"], 
                "pixelAnimIndex" => [4]
            ],
		1 => [
                "letters" => ["purple", "red"], 
                "anims" => ["LEFT", "RIGHT"], 
                "strumAnims" => ["LEFT", "RIGHT"], 
                "pixelAnimIndex" => [0, 3]
            ],
		2 => [
                "letters" => ["purple", "white", "red"], 
                "anims" => ["LEFT", "UP", "RIGHT"], 
                "strumAnims" => ["LEFT", "SPACE", "RIGHT"], 
                "pixelAnimIndex" => [0, 4, 3]
            ],
		3 => [
                "letters" => ["purple", "blue", "green", "red"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT"], 
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3]
            ],

		4 => [
                "letters" => ["purple", "blue", "white", "green", "red"], 
                "anims" => ["LEFT", "DOWN", "UP", "UP", "RIGHT"],
			    "strumAnims" => ["LEFT", "DOWN", "SPACE", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 4, 2, 3]
            ],
		5 => [
                "letters" => ["purple", "green", "red", "yellow", "blue", "darkblue"], 
                "anims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"],
			    "strumAnims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"], 
                "pixelAnimIndex" => [0, 2, 3, 5, 1, 8]
            ],
		6 => [
                "letters" => ["purple", "green", "red", "white", "yellow", "blue", "darkblue"], 
                "anims" => ["LEFT", "UP", "RIGHT", "UP", "LEFT", "DOWN", "RIGHT"],
			    "strumAnims" => ["LEFT", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "RIGHT"], 
                "pixelAnimIndex" => [0, 2, 3, 4, 5, 1, 8]
            ],
		7 => [
                "letters" => ["purple", "blue", "green", "red", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "UP", "DOWN", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
			    "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 5, 6, 7, 8]
            ],
		8 => [
                "letters" => ["purple", "blue", "green", "red", "white", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
		        "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 4, 5, 6, 7, 8]
            ],
		9 => [
                "letters" => ["purple", "blue", "green", "red", "white", "whiteCircle", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
		        "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 4, 13, 5, 6, 7, 8]
            ],
        10 => [
                "letters" => ["purple", "blue", "green", "red", "purpleCircle", "white", "redCircle", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "SPACE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 9, 4, 12, 5, 6, 7, 8]
            ],
        11 => [
                "letters" => ["purple", "blue", "green", "red", "purpleCircle", "blueCircle", "greenCircle", "redCircle", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 11, 12, 5, 6, 7, 8]
            ],
        12 => [
                "letters" => ["purple", "blue", "green", "red", "purpleCircle", "blueCircle", "whiteCircle", "greenCircle", "redCircle", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 13, 11, 12, 5, 6, 7, 8]
            ],
        13 => [
                "letters" => ["purple", "blue", "green", "red", "purpleCircle", "blueCircle", "white", "whiteCircle", "greenCircle", "redCircle", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "UP", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "SPACE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 4, 13, 11, 12, 5, 6, 7, 8]
            ],
        14 => [
                "letters" => ["purple", "blue", "green", "red", "purpleCircle", "blueCircle", "white", "whiteCircle", "white", "greenCircle", "redCircle", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "UP", "UP", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "SPACE", "CIRCLE", "SPACE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 4, 13, 4, 11, 12, 5, 6, 7, 8]
            ],
        15 => [
                "letters" => ["purple", "blue", "green", "red", "purpleCircle", "blueCircle", "greenCircle", "redCircle", "yellowCircle", "violetCircle", "darkredCircle", "darkblueCircle", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 11, 12, 14, 15, 16, 17, 5, 6, 7, 8]
            ],
        16 => [
                "letters" => ["purple", "blue", "green", "red", "purpleCircle", "blueCircle", "greenCircle", "redCircle", "whiteCircle", "yellowCircle", "violetCircle", "darkredCircle", "darkblueCircle", "yellow", "violet", "darkred", "darkblue"], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 11, 12, 13, 14, 15, 16, 17, 5, 6, 7, 8]
        ],
        17 => [
                "letters" => ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'darkred', 'darkblue',
                'purpleCircle', 'blueCircle', 'greenCircle', 'redCircle', 'whiteCircle', 'yellowCircle', 'violetCircle', 'darkredCircle', 'darkblueCircle'], 
                "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT",
                "LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
                "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT", 
                "LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], 
                "pixelAnimIndex" => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
        ],
	];

    
    public static var scales:Array<Float> = [
		0.9, // 1k
		0.85, //2k
		0.8, //3k
		0.7, //4k
		0.66, //5k
		0.6, //6k
		0.55, //7k
		0.50, //8k
		0.46, //9k
		0.39, //10k
		0.36, //11k
		0.32, //12k
		0.31, //13k
		0.31, //14k
		0.3, //15k
        0.26, //16k
        0.26, //17k
        0.22 //18k
    ]; 
	public static var lessX:Array<Int> = [
		0, // 1k
		0, // 2k
		0, //3k
		0, //4k
		0, //5k
		8, //6k
		7, //7k
		8, //8k
		8, //9k
		7, //10k
		6, //11k
		6, //12k
		8, //13k
		7, //14k
		6, //15k
        7, //16k
        6, // 17k
        6 //18k
    ];

    public static var noteSep:Array<Int> = [
        0, //1k
        0, //2k
        1, //3k
        1, //4k
        2, //5k
        2, //6k
        2, //7k
        3, //8k
        3, //9k
        4, //10k
        4, //11k
        5, //12k
        6, //13k
        6, //14k
        7, //15k
        6, //16k
        5//18k
    ];

    public static var offsetX:Array<Float> = [
        150, //1k
        89,//2k
        0, //3k
        0, //4k
        0, //5k
        0, //6k
        0, //7k
        0, //8k
        0, //9k
        0, //10k
        0, //11k
        0, //12k
        0, //13k
        0, //14k
        0, //15k
        0, //16k
        0, //17k
        0 //18k
    ];

    // i wont comment fuck you
    public static var gun:Array<Int> = [
        1, 
        2, 
        3, 
        4, 
        5, 
        6, 
        7, 
        8, 
        9, 
        10, 
        11, 
        12, 
        13,
        14,
        15,
        16,
        17,
        18
    ];

    public static var restPosition:Array<Float> = [
        0, //1k
        0, //2k
        0, //3k
        0, //4k
        25, //5k
        32,//6k
        46, //7k
        52, //8k
        60, //9k
        40, //10k
        45, //11k
        30, //12k
        30, //13k
        29,// 14k
        72, //15k
        37, // 16k
        61, //17k
        16 //18k
    ];

    public static var gridSizes:Array<Int> = [
        40, //1k
        40, //2k
        40, //3k
        40, //4k
        40, //5k
        40, //6k
        40, //7k
        40, //8k
        40, //9k
        35, //10k
        30, //11k
        25, //12k
        25, //13k
        20, //14k
        20, //15k
        20, //16k
        20, //17k
        15 //18k
    ];

    public static var splashScales:Array<Float> = [
        1.3, //1k
        1.2, //2k
        1.1, //3k
        1, //4k
        1, //5k
        0.9, //6k
        0.8,//7k
        0.7, //8k
        0.6, //9k
        0.5, //10k
        0.4, //11k
        0.3, //12k
        0.3, //13k
        0.3, //14k
        0.2, //15k
        0.18, //16k
        0.18, //17k
        0.15 //18k
    ];

    public static var pixelScales:Array<Float> = [
        1.2, //1k
        1.15, //2k
        1.1, //3k
        1, //4k
        0.9, //5k
        0.83, //6k
        0.8, //7k
        0.74, //8k
        0.7, //9k
        0.6, //10k
        0.55,//11k
        0.5, //12k
        0.48, //13k
        0.48, //14k
        0.42, //15k
        0.38, //16k
        0.38, //17k
        0.32 //18k
    ];
}

class Keybinds
{
    public static function optionShit():Array<Dynamic> {
        return [
            ['1 KEY'],
            ['Center', 'note_one1'],
            [''],
            ['2 KEYS'],
            ['Left', 'note_two1'],
            ['Right', 'note_two2'],
            [''],
            ['3 KEYS'],
            ['Left', 'note_three1'],
            ['Center', 'note_three2'],
            ['Right', 'note_three3'],
            [''],
            ['4 KEYS'],
            ['Left', 'note_left'],
            ['Down', 'note_down'],
            ['Up', 'note_up'],
            ['Right', 'note_right'],
            [''],
            ['5 KEYS'],
            ['Left', 'note_five1'],
            ['Down', 'note_five2'],
            ['Center', 'note_five3'],
            ['Up', 'note_five4'],
            ['Right', 'note_five5'],
            [''],
            ['6 KEYS'],
            ['Left 1', 'note_six1'],
            ['Up', 'note_six2'],
            ['Right 1', 'note_six3'],
            ['Left 2', 'note_six4'],
            ['Down', 'note_six5'],
            ['Right 2', 'note_six6'],
            [''],
            ['7 KEYS'],
            ['Left 1', 'note_seven1'],
            ['Up', 'note_seven2'],
            ['Right 1', 'note_seven3'],
            ['Center', 'note_seven4'],
            ['Left 2', 'note_seven5'],
            ['Down', 'note_seven6'],
            ['Right 2', 'note_seven7'],
            [''],
            ['8 KEYS'],
            ['Left 1', 'note_eight1'],
            ['Down 1', 'note_eight2'],
            ['Up 1', 'note_eight3'],
            ['Right 1', 'note_eight4'],
            ['Left 2', 'note_eight5'],
            ['Down 2', 'note_eight6'],
            ['Up 2', 'note_eight7'],
            ['Right 2', 'note_eight8'],
            [''],
            ['9 KEYS'],
            ['Left 1', 'note_nine1'],
            ['Down 1', 'note_nine2'],
            ['Up 1', 'note_nine3'],
            ['Right 1', 'note_nine4'],
            ['Center', 'note_nine5'],
            ['Left 2', 'note_nine6'],
            ['Down 2', 'note_nine7'],
            ['Up 2', 'note_nine8'],
            ['Right 2', 'note_nine9'],
            [''],
            ['10 KEYS'],
            ['Left 1', 'note_ten1'],
            ['Down 1', 'note_ten2'],
            ['Up 1', 'note_ten3'],
            ['Right 1', 'note_ten4'],
            ['Center 1', 'note_ten5'],
            ['Center 2', 'note_ten6'],
            ['Left 2', 'note_ten7'],
            ['Down 2', 'note_ten8'],
            ['Up 2', 'note_ten9'],
            ['Right 2', 'note_ten10'],
            [''],
            ['11 KEYS'],
            ['Left 1', 'note_elev1'],
            ['Down 1', 'note_elev2'],
            ['Up 1', 'note_elev3'],
            ['Right 1', 'note_elev4'],
            ['Left 2', 'note_elev5'],
            ['Center 2', 'note_elev6'],
            ['Right 2', 'note_elev7'],
            ['Left 3', 'note_elev8'],
            ['Down 2', 'note_elev9'],
            ['Up 2', 'note_elev10'],
            ['Right 3', 'note_elev11'],
            [''],
            ['12 KEYS'],
            ['Left 1', 'note_twel1'],
            ['Down 1', 'note_twel2'],
            ['Up 1', 'note_twel3'],
            ['Right 1', 'note_twel4'],
            ['Left 2', 'note_twel5'],
            ['Down 2', 'note_twel6'],
            ['Up 2', 'note_twel7'],
            ['Right 2', 'note_twel8'],
            ['Left 3', 'note_twel9'],
            ['Down 3', 'note_twel10'],
            ['Up 3', 'note_twel11'],
            ['Right 3', 'note_twel12'],
            [''],
            ['13 KEYS'],
            ['Left 1', 'note_thir1'],
            ['Down 1', 'note_thir2'],
            ['Up 1', 'note_thir3'],
            ['Right 1', 'note_thir4'],
            ['Left 2', 'note_thir5'],
            ['Down 2', 'note_thir6'],
            ['Center', 'note_thir7'],
            ['Up 2', 'note_thir8'],
            ['Right 2', 'note_thir9'],
            ['Left 3', 'note_thir10'],
            ['Down 3', 'note_thir11'],
            ['Up 3', 'note_thir12'],
            ['Right 3', 'note_thir13'],
            ['14 KEYS'],
            ['Left 1', 'note_fourt1'],
            ['Down 1', 'note_fourt2'],
            ['Up 1', 'note_fourt3'],
            ['Right 1', 'note_fourt4'],
            ['Left 2', 'note_fourt5'],
            ['Down 2', 'note_fourt6'],
            ['Center 1', 'note_fourt7'],
            ['Center 2', 'note_fourt8'],
            ['Up 2', 'note_fourt9'],
            ['Right 2', 'note_fourt10'],
            ['Left 3', 'note_fourt11'],
            ['Down 3', 'note_fourt12'],
            ['Up 3', 'note_fourt13'],
            ['Right 3', 'note_fourt14'],
            [''],
            ['15 KEYS'],
            ['Left 1', 'note_151'],
            ['Down 1', 'note_152'],
            ['Up 1', 'note_153'],
            ['Right 1', 'note_154'],
            ['Left 2', 'note_155'],
            ['Down 2', 'note_156'],
            ['Center 1', 'note_157'],
            ['Center 2', 'note_158'],
            ['Center 3', 'note_159'],
            ['Up 2', 'note_1510'],
            ['Right 2', 'note_1511'],
            ['Left 3', 'note_1512'],
            ['Down 3', 'note_1513'],
            ['Up 3', 'note_1514'],
            ['Right 3', 'note_1515'],
            [''],
            ['16 KEYS'],
            ['Left 1', 'note_161'],
            ['Down 1', 'note_162'],
            ['Up 1', 'note_163'],
            ['Right 1', 'note_164'],
            ['Left 2', 'note_165'],
            ['Down 2', 'note_166'],
            ['Up 2', 'note_167'],
            ['Right 2', 'note_168'],
            ['Left 3', 'note_169'],
            ['Down 3', 'note_1610'],
            ['Up 3', 'note_1611'],
            ['Right 3', 'note_1612'],
            ['Left 4', 'note_1613'],
            ['Down 4', 'note_1614'],
            ['Up 4', 'note_1615'],
            ['Right 4', 'note_1616'],
            [''],
            ['17 KEYS'],
            ['Left 1', 'note_171'],
            ['Down 1', 'note_172'],
            ['Up 1', 'note_173'],
            ['Right 1', 'note_174'],
            ['Left 2', 'note_175'],
            ['Down 2', 'note_176'],
            ['Up 2', 'note_177'],
            ['Right 2', 'note_178'],
            ['Center', 'note_179'],
            ['Left 3', 'note_1710'],
            ['Down 3', 'note_1711'],
            ['Up 3', 'note_1712'],
            ['Right 3', 'note_1713'],
            ['Left 4', 'note_1714'],
            ['Down 4', 'note_1715'],
            ['Up 4', 'note_1717'],
            ['Right 4', 'note_1717'],
            [''],
            ['18 KEYS FINAL'],
            ['Left 1', 'note_181'],
            ['Down 1', 'note_182'],
            ['Up 1', 'note_183'],
            ['Right 1', 'note_184'],
            ['Center 1', 'note_185'],
            ['Left 2', 'note_186'],
            ['Down 2', 'note_187'],
            ['Up 2', 'note_188'],
            ['Right 2', 'note_189'],
            ['Left 3', 'note_1810'],
            ['Down 3', 'note_1811'],
            ['Up 3', 'note_1812'],
            ['Right 3', 'note_1813'],
            ['Center 2', 'note_1814'],
            ['Left 4', 'note_1815'],
            ['Down 4', 'note_1816'],
            ['Up 4', 'note_1817'],
            ['Right 4', 'note_1818'],
            [''],
            ['UI'],
            ['Left', 'ui_left'],
            ['Down', 'ui_down'],
            ['Up', 'ui_up'],
            ['Right', 'ui_right'],
            [''],
            ['Reset', 'reset'],
            ['Accept', 'accept'],
            ['Back', 'back'],
            ['Pause', 'pause'],
            [''],
            ['VOLUME'],
            ['Mute', 'volume_mute'],
            ['Up', 'volume_up'],
            ['Down', 'volume_down'],
            [''],
            ['DEBUG'],
            ['Key 1', 'debug_1'],
            ['Key 2', 'debug_2']
        ];
    }

    public static function fill():Array<Array<Dynamic>>
    {
        return [
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_one1'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_two1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_two2'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three3'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five5'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six6'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven7'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight8'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine9'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten9')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten10'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev9')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev10')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_elev11'))
			],
            [
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel9')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel10')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel11')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_twel12'))
            ],
            [
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir9')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir10')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir11')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir12')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_thir13'))
            ],
            [
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt9')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt10')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt11')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt12')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt13')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_fourt14'))
            ],
            [
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_151')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_152')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_153')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_154')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_155')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_156')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_157')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_158')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_159')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1510')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1511')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1512')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1513')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1514')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1515'))
            ],
            [
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_161')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_162')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_163')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_164')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_165')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_166')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_167')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_168')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_169')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1610')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1611')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1612')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1613')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1614')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1615')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1616'))
            ],
            [
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_171')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_172')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_173')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_174')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_175')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_176')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_177')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_178')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_179')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1710')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1711')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1712')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1713')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1714')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1715')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1716')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1717'))
            ],
            [
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_181')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_182')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_183')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_184')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_185')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_186')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_187')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_188')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_189')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1810')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1811')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1812')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1813')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1814')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1815')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1816')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1817')),
                ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_1818'))
            ]
		];
    }
}