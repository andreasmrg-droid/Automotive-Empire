## NameData.gd
## Static name data for all nationalities.
## Stored as GDScript dictionary - faster than JSON, no parse errors.
extends Node

var data: Dictionary = {
	"Italian": {
		"male_seeds": ["Marco", "Luca", "Andrea", "Matteo", "Lorenzo", "Giovanni", "Francesco", "Roberto", "Alessandro", "Davide", "Stefano", "Riccardo", "Simone", "Gabriele", "Edoardo"],
		"female_seeds": ["Giulia", "Sofia", "Valentina", "Chiara", "Alessia", "Francesca", "Martina", "Laura", "Sara", "Elena", "Beatrice", "Federica", "Silvia", "Elisa", "Roberta"],
		"surname_seeds": ["Rossi", "Ferrari", "Colombo", "Ricci", "Marino", "Greco", "Bruno", "Gallo", "Conti", "De Luca", "Mancini", "Costa", "Giordano", "Rizzo", "Lombardi"],
		"male_syl": ["Mar", "Lu", "An", "Gi", "Ro", "Fab", "Ste", "Dav", "Ale", "Ren", "Nic", "Pie", "Vin", "Sal", "Tor"],
		"female_syl": ["Giu", "So", "Val", "Chi", "Ale", "Mar", "Fra", "Sar", "Ele", "Bea", "Fed", "Sil", "Eli", "Rob", "Cla"],
		"sur_roots": ["Ross", "Ferr", "Colomb", "Ricc", "Marin", "Grec", "Brun", "Gall", "Cont", "Manc", "Cost", "Giord", "Rizz", "Lomb", "Espos"],
		"sur_end": ["i", "o", "elli", "etti", "ini", "one", "ino", "ello", "acci", "ucci"]
	},
	"Spanish": {
		"male_seeds": ["Carlos", "Miguel", "Alejandro", "Diego", "Pablo", "Javier", "Antonio", "Manuel", "Fernando", "Rafael", "Sergio", "Alberto", "Raul", "Ivan", "Adrian","Felix"],
		"female_seeds": ["Sofia", "Lucia", "Maria", "Carmen", "Isabella", "Elena", "Ana", "Marta", "Paula", "Laura", "Cristina", "Patricia", "Beatriz", "Alicia", "Nuria", "Gemma"],
		"surname_seeds": ["Garcia", "Martinez", "Lopez", "Sanchez", "Fernandez", "Gonzalez", "Rodriguez", "Perez", "Alvarez", "Torres", "Ramirez", "Flores", "Moreno", "Jimenez", "Ruiz", "Carasco"],
		"male_syl": ["Car", "Mig", "Ale", "Die", "Pab", "Jav", "Ant", "Man", "Fer", "Raf", "Ser", "Alb", "Rau", "Iva", "Adr"],
		"female_syl": ["Sof", "Luc", "Mar", "Car", "Isa", "Ele", "Ana", "Pau", "Lau", "Cri", "Pat", "Bea", "Ali", "Nur", "Ire"],
		"sur_roots": ["Garc", "Mart", "Lop", "Sanch", "Fern", "Gonz", "Rodr", "Per", "Alv", "Torr", "Ram", "Flor", "Mor", "Jim", "Ru"],
		"sur_end": ["ez", "es", "oz", "az", "iz", "ero", "era", "ado", "eda", "illo"]
	},
	"French": {
		"male_seeds": ["Pierre", "Jules", "Esteban", "Charles", "Antoine", "Nicolas", "Thomas", "Julien", "Alexandre", "Maxime", "Lucas", "Hugo", "Theo", "Baptiste", "Romain"],
		"female_seeds": ["Camille", "Lea", "Manon", "Chloe", "Emma", "Ines", "Clara", "Lucie", "Marie", "Julie", "Sophie", "Alice", "Charlotte", "Pauline", "Amelie"],
		"surname_seeds": ["Gasly", "Ocon", "Vergne", "Grosjean", "Panis", "Dupont", "Martin", "Bernard", "Dubois", "Laurent", "Simon", "Michel", "Lefevre", "Roux", "Moreau"],
		"male_syl": ["Pie", "Jul", "Est", "Cha", "Ant", "Nic", "Tho", "Ale", "Max", "Luc", "Hug", "The", "Bap", "Rom", "Flo"],
		"female_syl": ["Cam", "Lea", "Man", "Chl", "Emm", "Ine", "Cla", "Luc", "Mar", "Jul", "Sop", "Ali", "Pau", "Ame", "Elo"],
		"sur_roots": ["Gasl", "Dup", "Mart", "Bern", "Dub", "Laur", "Sim", "Mich", "Lef", "Roux", "Mor", "Petit", "Grand", "Blanc", "Noir"],
		"sur_end": ["ot", "et", "eau", "on", "in", "ant", "ier", "ard", "aux", "eux"]
	},
	"German": {
		"male_seeds": ["Sebastian", "Nico", "Felix", "Maximilian", "Leon", "Lukas", "Jonas", "Elias", "Noah", "Finn", "Paul", "Ben", "Tim", "Jan", "Moritz"],
		"female_seeds": ["Anna", "Laura", "Sarah", "Julia", "Hannah", "Lea", "Emma", "Mia", "Lena", "Sophie", "Lisa", "Katharina", "Franziska", "Johanna", "Clara"],
		"surname_seeds": ["Muller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker", "Schulz", "Hoffmann", "Schafer", "Koch", "Richter", "Klein", "Wolf"],
		"male_syl": ["Seb", "Nic", "Fel", "Max", "Leo", "Luk", "Jon", "Eli", "Noa", "Fin", "Pau", "Ben", "Tim", "Jan", "Mor"],
		"female_syl": ["Ann", "Lau", "Sar", "Jul", "Han", "Lea", "Emm", "Mia", "Len", "Sop", "Lis", "Kat", "Fra", "Joh", "Cla"],
		"sur_roots": ["Mull", "Schm", "Schn", "Fisch", "Web", "Mey", "Wagn", "Beck", "Schulz", "Hoff", "Koch", "Richt", "Klein", "Wolf", "Braun"],
		"sur_end": ["er", "mann", "en", "el", "ke", "ler", "ner", "ger", "fer", "her"]
	},
	"British": {
		"male_seeds": ["Jack", "George", "Lewis", "Oliver", "Harry", "James", "William", "Thomas", "Alexander", "Henry", "Charlie", "Edward", "Frederick", "Arthur", "Archie"],
		"female_seeds": ["Emma", "Olivia", "Sophia", "Isabella", "Charlotte", "Amelia", "Lily", "Grace", "Eleanor", "Victoria", "Alice", "Beatrice", "Rosie", "Harriet", "Imogen"],
		"surname_seeds": ["Hamilton", "Russell", "Norris", "Button", "Coulthard", "Smith", "Jones", "Williams", "Taylor", "Brown", "Davies", "Evans", "Wilson", "Thomas", "Roberts"],
		"male_syl": ["Jac", "Geo", "Lew", "Oli", "Har", "Jam", "Wil", "Tho", "Ale", "Hen", "Cha", "Edw", "Fre", "Art", "Arc"],
		"female_syl": ["Emm", "Oli", "Sop", "Isa", "Cha", "Ame", "Lil", "Gra", "Ele", "Vic", "Ali", "Bea", "Ros", "Har", "Imo"],
		"sur_roots": ["Ham", "Russ", "Norr", "Butt", "Coul", "Smit", "Jon", "Willi", "Tayl", "Brow", "Dav", "Evan", "Wils", "Thom", "Rob"],
		"sur_end": ["ton", "ell", "is", "on", "ard", "er", "son", "ley", "ford", "wood"]
	},
	"Dutch": {
		"male_seeds": ["Max", "Lando", "Nyck", "Guido", "Robin", "Daan", "Lars", "Sven", "Koen", "Thijs", "Joris", "Bram", "Ruben", "Niels", "Bas"],
		"female_seeds": ["Emma", "Sophie", "Lisa", "Anna", "Lotte", "Fleur", "Isa", "Noor", "Roos", "Lies", "Femke", "Eline", "Vera", "Anouk", "Iris"],
		"surname_seeds": ["Verstappen", "De Vries", "Van Amersfoort", "Bleekemolen", "Doornbos", "Bakker", "Janssen", "De Jong", "Visser", "Peters", "Smit", "Van Dijk", "Meijer", "Mulder", "Berg"],
		"male_syl": ["Max", "Lan", "Nyc", "Gui", "Rob", "Daa", "Lar", "Sve", "Koe", "Thi", "Jor", "Bra", "Rub", "Nie", "Bas"],
		"female_syl": ["Emm", "Sop", "Lis", "Ann", "Lot", "Fle", "Isa", "Noo", "Roo", "Lie", "Fem", "Eli", "Ver", "Ano", "Iri"],
		"sur_roots": ["Bak", "Jans", "Jong", "Viss", "Pet", "Smit", "Dijk", "Meij", "Muld", "Berg", "Haan", "Bos", "Kok", "Kuip", "Post"],
		"sur_end": ["er", "en", "man", "ink", "stra", "sma", "inga", "huis", "dam", "dijk"]
	},
	"Belgian": {
		"male_seeds": ["Thierry", "Stoffel", "Sebastien", "Dries", "Thibaut", "Axel", "Remi", "Nicolas", "Cedric", "Pieter", "Luca", "Yannick", "Mathieu", "Julien", "Kevin"],
		"female_seeds": ["Emma", "Julie", "Laura", "Sarah", "Nathalie", "Elise", "Charlotte", "Amelie", "Ines", "Celine", "Valerie", "Aurelie", "Laure", "Manon", "Pauline"],
		"surname_seeds": ["Neuville", "Vandoorne", "Loeb", "Munster", "Tsjoen", "Maes", "Peeters", "Janssen", "Claes", "Leclercq", "Dupont", "Lambert", "Simon", "Dubois", "Lecomte"],
		"male_syl": ["Thi", "Sto", "Seb", "Dri", "Tib", "Axe", "Rem", "Nic", "Ced", "Pie", "Luc", "Yan", "Mat", "Jul", "Kev"],
		"female_syl": ["Emm", "Jul", "Lau", "Sar", "Nat", "Eli", "Cha", "Ame", "Ine", "Cel", "Val", "Aur", "Man", "Pau", "Cla"],
		"sur_roots": ["Neuv", "Vand", "Loe", "Mun", "Tsjo", "Mae", "Peet", "Jans", "Clae", "Lecl", "Dup", "Lamb", "Sim", "Dub", "Lec"],
		"sur_end": ["ille", "oorne", "b", "ster", "en", "s", "ers", "sen", "s", "ercq"]
	},
	"Portuguese": {
		"male_seeds": ["Bruno", "Ricardo", "Joao", "Pedro", "Nuno", "Tiago", "Andre", "Miguel", "Rui", "Paulo", "Antonio", "Sergio", "Vitor", "Hugo", "Luis"],
		"female_seeds": ["Ana", "Maria", "Sofia", "Beatriz", "Ines", "Catarina", "Mariana", "Rita", "Patricia", "Filipa", "Joana", "Carla", "Sandra", "Teresa", "Madalena"],
		"surname_seeds": ["Silva", "Santos", "Ferreira", "Pereira", "Oliveira", "Costa", "Rodrigues", "Martins", "Jesus", "Sousa", "Fernandes", "Goncalves", "Gomes", "Lopes", "Marques"],
		"male_syl": ["Bru", "Ric", "Joa", "Ped", "Nun", "Tia", "And", "Mig", "Rui", "Pau", "Ant", "Ser", "Vit", "Hug", "Lui"],
		"female_syl": ["Ana", "Mar", "Sof", "Bea", "Ine", "Cat", "Mar", "Rit", "Pat", "Fil", "Joa", "Car", "San", "Ter", "Mad"],
		"sur_roots": ["Silv", "Sant", "Ferr", "Per", "Oliv", "Cost", "Rodr", "Mart", "Jes", "Sous", "Fern", "Gonc", "Gom", "Lop", "Marq"],
		"sur_end": ["a", "os", "es", "eira", "o", "ues", "ins", "us", "as", "ez"]
	},
	"Greek": {
		"male_seeds": ["Nikos", "Kostas", "Giorgos", "Dimitris", "Alexandros", "Petros", "Yannis", "Stavros", "Christos", "Panagiotis", "Vasilis", "Michalis", "Thanasis", "Spyros", "Andreas","Dimosthenis"],
		"female_seeds": ["Maria", "Eleni", "Katerina", "Sofia", "Anna", "Christina", "Ioanna", "Despina", "Athina", "Vasiliki", "Dimitra", "Stavroula", "Evgenia", "Panagiota", "Theodora"],
		"surname_seeds": ["Papadopoulos", "Georgiou", "Nikolaou", "Andreou", "Christodoulou", "Petrou", "Stavrou", "Ioannou", "Kyriakou", "Konstantinou", "Alexiou", "Demetriou", "Vassiliou", "Michaelides", "Antoniou"],
		"male_syl": ["Nik", "Kos", "Gio", "Dim", "Ale", "Pet", "Yan", "Sta", "Chr", "Pan", "Vas", "Mic", "Tha", "Spy", "And"],
		"female_syl": ["Mar", "Ele", "Kat", "Sof", "Ann", "Chr", "Ioa", "Des", "Ath", "Vas", "Dim", "Sta", "Evg", "Pan", "The"],
		"sur_roots": ["Papd", "Georg", "Nikol", "Andre", "Christ", "Petr", "Stavr", "Iann", "Kyri", "Konst", "Alex", "Demet", "Vasil", "Micha", "Anton"],
		"sur_end": ["opoulos", "iou", "aou", "eou", "ou", "akis", "idis", "ides", "akos", "as"]
	},
	"Swedish": {
		"male_seeds": ["Marcus", "Johan", "Erik", "Lars", "Anders", "Mikael", "Jonas", "Mattias", "Stefan", "Henrik", "Pontus", "Viktor", "Gustav", "Axel", "Oscar"],
		"female_seeds": ["Emma", "Anna", "Maja", "Linnea", "Sofia", "Ida", "Elin", "Sara", "Johanna", "Klara", "Hanna", "Frida", "Lina", "Ebba", "Alva"],
		"surname_seeds": ["Eriksson", "Johansson", "Andersson", "Karlsson", "Nilsson", "Larsson", "Svensson", "Gustafsson", "Pettersson", "Lindgren", "Magnusson", "Berg", "Lindqvist", "Holm", "Strand"],
		"male_syl": ["Mar", "Joh", "Eri", "Lar", "And", "Mik", "Jon", "Mat", "Ste", "Hen", "Pon", "Vik", "Gus", "Axe", "Osc"],
		"female_syl": ["Emm", "Ann", "Maj", "Lin", "Sof", "Ida", "Eli", "Sar", "Joh", "Kla", "Han", "Fri", "Lin", "Ebb", "Alv"],
		"sur_roots": ["Erik", "Johan", "Anders", "Karl", "Nils", "Lars", "Sven", "Gustaf", "Petter", "Lind", "Magn", "Berg", "Strand", "Holm", "Gren"],
		"sur_end": ["sson", "sen", "gren", "berg", "qvist", "lund", "holm", "strand", "mark", "back"]
	},
	"Danish": {
		"male_seeds": ["Magnus", "Christian", "Mikkel", "Frederik", "Lars", "Anders", "Jonas", "Rasmus", "Martin", "Thomas", "Kasper", "Mads", "Emil", "Nikolaj", "Oliver"],
		"female_seeds": ["Emma", "Sofia", "Ida", "Anna", "Laura", "Caroline", "Mette", "Katrine", "Astrid", "Maja", "Louise", "Camilla", "Nanna", "Pernille", "Trine"],
		"surname_seeds": ["Nielsen", "Jensen", "Hansen", "Pedersen", "Andersen", "Christensen", "Larsen", "Sorensen", "Rasmussen", "Jorgensen", "Petersen", "Madsen", "Kristensen", "Olsen", "Thomsen"],
		"male_syl": ["Mag", "Chr", "Mik", "Fre", "Lar", "And", "Jon", "Ras", "Mar", "Tho", "Kas", "Mad", "Emi", "Nik", "Oli"],
		"female_syl": ["Emm", "Sof", "Ida", "Ann", "Lau", "Car", "Met", "Kat", "Ast", "Maj", "Lou", "Cam", "Nan", "Per", "Tri"],
		"sur_roots": ["Niel", "Jens", "Hans", "Peder", "Ander", "Christen", "Lars", "Soren", "Rasmus", "Jorgen", "Peter", "Mads", "Kristen", "Ols", "Thom"],
		"sur_end": ["sen", "en", "son", "ssen", "ersen", "ansen", "ssen", "sren", "ussen", "ensen"]
	},
	"Finnish": {
		"male_seeds": ["Mikko", "Jari", "Kimi", "Valtteri", "Mika", "Pekka", "Juha", "Timo", "Heikki", "Ari", "Teemu", "Sami", "Janne", "Petteri", "Ville"],
		"female_seeds": ["Aino", "Siiri", "Helmi", "Emilia", "Laura", "Hanna", "Sanna", "Minna", "Tiina", "Leena", "Kaisa", "Miia", "Johanna", "Riikka", "Tuulia"],
		"surname_seeds": ["Makinen", "Gronholm", "Latvala", "Hirvonen", "Rovanpera", "Solberg", "Nieminen", "Korhonen", "Virtanen", "Makela", "Leinonen", "Heikkinen", "Koskinen", "Jarvinen", "Peltonen"],
		"male_syl": ["Mik", "Jar", "Kim", "Val", "Mik", "Pek", "Juh", "Tim", "Hei", "Ari", "Tee", "Sam", "Jan", "Pet", "Vil"],
		"female_syl": ["Ain", "Sii", "Hel", "Emi", "Lau", "Han", "San", "Min", "Tii", "Lee", "Kai", "Mii", "Joh", "Rii", "Tuu"],
		"sur_roots": ["Mak", "Gron", "Lat", "Hirv", "Rov", "Sol", "Niem", "Korh", "Virt", "Mak", "Lein", "Heikk", "Koski", "Jarv", "Pelt"],
		"sur_end": ["inen", "nen", "la", "maki", "berg", "aho", "jarvi", "koski", "niemi", "harju"]
	},
	"Norwegian": {
		"male_seeds": ["Magnus", "Petter", "Henning", "Mads", "Anders", "Stig", "Eyvind", "Rune", "Ole", "Kristoffer", "Tobias", "Vegard", "Sindre", "Erlend", "Tor"],
		"female_seeds": ["Emma", "Nora", "Ingrid", "Astrid", "Maja", "Sigrid", "Frida", "Thea", "Marte", "Hilde", "Silje", "Anette", "Camilla", "Marit", "Tone"],
		"surname_seeds": ["Solberg", "Ostberg", "Mikkelsen", "Eriksen", "Hansen", "Larsen", "Andersen", "Olsen", "Johnsen", "Berg", "Haugen", "Dahl", "Strand", "Bakke", "Vik"],
		"male_syl": ["Mag", "Pet", "Hen", "Mad", "And", "Sti", "Eyv", "Run", "Ole", "Kri", "Tob", "Veg", "Sin", "Erl", "Tor"],
		"female_syl": ["Emm", "Nor", "Ing", "Ast", "Maj", "Sig", "Fri", "The", "Mar", "Hil", "Sil", "Ane", "Cam", "Mar", "Ton"],
		"sur_roots": ["Sol", "Ost", "Mikkel", "Erik", "Hans", "Lars", "Anders", "Ols", "Johns", "Berg", "Haug", "Dahl", "Strand", "Bakk", "Vik"],
		"sur_end": ["berg", "en", "sen", "son", "ssen", "stad", "dal", "vik", "fjord", "holm"]
	},
	"Swiss": {
		"male_seeds": ["Sebastian", "Marc", "Michael", "Patrick", "Simon", "Noel", "Fabio", "Stefan", "Daniel", "Romain", "Loic", "Benoit", "Xavier", "Yann", "Cedric"],
		"female_seeds": ["Emma", "Lara", "Nicole", "Sandra", "Sabine", "Christine", "Nathalie", "Claudia", "Martina", "Julia", "Monika", "Silvia", "Andrea", "Kathrin", "Vreni"],
		"surname_seeds": ["Buemi", "Muller", "Berthon", "Lacroix", "Favre", "Dubois", "Martin", "Weber", "Fischer", "Zimmermann", "Schmid", "Brunner", "Meier", "Huber", "Koch"],
		"male_syl": ["Seb", "Mar", "Mic", "Pat", "Sim", "Noe", "Fab", "Ste", "Dan", "Rom", "Loi", "Ben", "Xav", "Yan", "Ced"],
		"female_syl": ["Emm", "Lar", "Nic", "San", "Sab", "Chr", "Nat", "Cla", "Mar", "Jul", "Mon", "Sil", "And", "Kat", "Vre"],
		"sur_roots": ["Bue", "Mull", "Berth", "Lacr", "Favr", "Dub", "Mart", "Web", "Fisch", "Zimm", "Schm", "Brunn", "Mei", "Hub", "Koch"],
		"sur_end": ["er", "on", "ois", "re", "is", "mann", "id", "ner", "ler", "i"]
	},
	"Austrian": {
		"male_seeds": ["Niki", "Gerhard", "Alexander", "Helmut", "Roland", "Christian", "Hannes", "Jochen", "Dieter", "Klaus", "Martin", "Stefan", "Thomas", "Andreas", "Lukas"],
		"female_seeds": ["Anna", "Maria", "Elisabeth", "Katharina", "Theresa", "Barbara", "Christina", "Monika", "Sabine", "Andrea", "Claudia", "Petra", "Sandra", "Nicole", "Julia"],
		"surname_seeds": ["Lauda", "Berger", "Wurz", "Klien", "Marko", "Huber", "Bauer", "Wagner", "Gruber", "Hofer", "Mayer", "Steiner", "Wimmer", "Egger", "Pichler"],
		"male_syl": ["Nik", "Ger", "Ale", "Hel", "Rol", "Chr", "Han", "Joc", "Die", "Kla", "Mar", "Ste", "Tho", "And", "Luk"],
		"female_syl": ["Ann", "Mar", "Eli", "Kat", "The", "Bar", "Chr", "Mon", "Sab", "And", "Cla", "Pet", "San", "Nic", "Jul"],
		"sur_roots": ["Laud", "Berg", "Wurz", "Kli", "Mark", "Hub", "Bau", "Wagn", "Grub", "Hof", "May", "Stein", "Wimm", "Egg", "Pich"],
		"sur_end": ["er", "en", "ner", "o", "statter", "mann", "ler", "ger", "l", "a"]
	},
	"Polish": {
		"male_seeds": ["Robert", "Kajetan", "Michal", "Pawel", "Marcin", "Tomasz", "Piotr", "Lukasz", "Maciej", "Jakub", "Bartosz", "Kamil", "Damian", "Rafal", "Krystian"],
		"female_seeds": ["Anna", "Maria", "Katarzyna", "Magdalena", "Agnieszka", "Monika", "Joanna", "Aleksandra", "Barbara", "Ewa", "Karolina", "Marta", "Natalia", "Paulina", "Wiktoria"],
		"surname_seeds": ["Kubica", "Kaminski", "Wisniewski", "Wojciechowski", "Kowalski", "Lewandowski", "Zielinski", "Szymanski", "Wozniak", "Dabrowski", "Kozlowski", "Jankowski", "Mazur", "Krawczyk", "Piotrowski"],
		"male_syl": ["Rob", "Kaj", "Mic", "Paw", "Mar", "Tom", "Pio", "Luk", "Mac", "Jak", "Bar", "Kam", "Dam", "Raf", "Kry"],
		"female_syl": ["Ann", "Mar", "Kat", "Mag", "Agn", "Mon", "Joa", "Ale", "Bar", "Ewa", "Kar", "Mar", "Nat", "Pau", "Wik"],
		"sur_roots": ["Kub", "Kam", "Wisn", "Wojc", "Kow", "Lew", "Ziel", "Szym", "Wozn", "Dabr", "Kozl", "Jank", "Maz", "Kraw", "Piotr"],
		"sur_end": ["ski", "ska", "owski", "owska", "ewski", "ewska", "inski", "inska", "czyk", "ak"]
	},
	"Czech": {
		"male_seeds": ["Martin", "Tomas", "Jan", "Petr", "Pavel", "Michal", "Jakub", "Ondrej", "Lukas", "David", "Radek", "Miroslav", "Vojtech", "Filip", "Jiri"],
		"female_seeds": ["Jana", "Marie", "Eva", "Petra", "Katerina", "Lucie", "Marketa", "Veronika", "Tereza", "Alena", "Hana", "Monika", "Lenka", "Ivana", "Martina"],
		"surname_seeds": ["Novak", "Novotny", "Dvorak", "Cerny", "Blaho", "Prochazka", "Kucera", "Vesely", "Horak", "Nemec", "Pokorny", "Marek", "Pospisil", "Hajek", "Kral"],
		"male_syl": ["Mar", "Tom", "Jan", "Pet", "Pav", "Mic", "Jak", "Ond", "Luk", "Dav", "Rad", "Mir", "Voj", "Fil", "Jir"],
		"female_syl": ["Jan", "Mar", "Eva", "Pet", "Kat", "Luc", "Mar", "Ver", "Ter", "Ale", "Han", "Mon", "Len", "Iva", "Mar"],
		"sur_roots": ["Nov", "Dvor", "Cern", "Blah", "Proch", "Kuc", "Vesel", "Hor", "Nem", "Pokorn", "Mar", "Posp", "Haj", "Kral", "Ruz"],
		"sur_end": ["ak", "ny", "ek", "ka", "a", "azka", "era", "y", "ak", "ek"]
	},
	"Hungarian": {
		"male_seeds": ["Zsolt", "Attila", "Gabor", "Zoltan", "Laszlo", "Tamas", "Peter", "Andras", "Tibor", "Istvan", "Ferenc", "Balazs", "Csaba", "Norbert", "Krisztian"],
		"female_seeds": ["Anna", "Eva", "Erzsebet", "Maria", "Katalin", "Agnes", "Judit", "Zsuzsanna", "Ildiko", "Margit", "Eszter", "Orsolya", "Timea", "Renata", "Viktoria"],
		"surname_seeds": ["Nagy", "Kovacs", "Toth", "Szabo", "Horvath", "Varga", "Kiss", "Molnar", "Nemeth", "Fekete", "Pap", "Balogh", "Takacs", "Juhasz", "Farkas"],
		"male_syl": ["Zso", "Att", "Gab", "Zol", "Las", "Tam", "Pet", "And", "Tib", "Ist", "Fer", "Bal", "Csa", "Nor", "Kri"],
		"female_syl": ["Ann", "Eva", "Erz", "Mar", "Kat", "Agn", "Jud", "Zsu", "Ild", "Mar", "Esz", "Ors", "Tim", "Ren", "Vik"],
		"sur_roots": ["Nagy", "Kov", "Tot", "Szab", "Horv", "Varg", "Kiss", "Moln", "Nem", "Fek", "Pap", "Bal", "Tak", "Juh", "Fark"],
		"sur_end": ["y", "acs", "h", "o", "ath", "a", "s", "ar", "eth", "ete"]
	},
	"Romanian": {
		"male_seeds": ["Alexandru", "Andrei", "Mihai", "Cristian", "Bogdan", "Razvan", "Catalin", "Marius", "Cosmin", "Ionut", "Florin", "Radu", "Vlad", "Octavian", "Dragos"],
		"female_seeds": ["Maria", "Elena", "Ioana", "Ana", "Cristina", "Andreea", "Alexandra", "Mihaela", "Alina", "Raluca", "Simona", "Gabriela", "Roxana", "Claudia", "Nicoleta"],
		"surname_seeds": ["Popescu", "Ionescu", "Popa", "Constantin", "Gheorghe", "Stoica", "Matei", "Dinu", "Marin", "Dumitru", "Stan", "Badea", "Tudor", "Moldovan", "Rus"],
		"male_syl": ["Ale", "And", "Mih", "Cri", "Bog", "Raz", "Cat", "Mar", "Cos", "Ion", "Flo", "Rad", "Vla", "Oct", "Dra"],
		"female_syl": ["Mar", "Ele", "Ioa", "Ana", "Cri", "And", "Ale", "Mih", "Ali", "Ral", "Sim", "Gab", "Rox", "Cla", "Nic"],
		"sur_roots": ["Pop", "Ion", "Pop", "Const", "Gheor", "Sto", "Mat", "Din", "Mar", "Dum", "Stan", "Bad", "Tud", "Mold", "Rus"],
		"sur_end": ["escu", "escu", "a", "antin", "ghe", "ica", "ei", "u", "in", "itru"]
	},
	"Croatian": {
		"male_seeds": ["Ivan", "Marko", "Luka", "Tomislav", "Ante", "Marin", "Damir", "Nikola", "Josip", "Kresimir", "Zvonimir", "Branimir", "Domagoj", "Stjepan", "Vedran"],
		"female_seeds": ["Ana", "Maja", "Iva", "Petra", "Marina", "Ivana", "Sanja", "Kristina", "Nikolina", "Antonija", "Lucija", "Mirela", "Vesna", "Dora", "Tanja"],
		"surname_seeds": ["Horvat", "Kovacevic", "Babic", "Maric", "Tomic", "Novak", "Juric", "Petrovic", "Blazevic", "Kralj", "Vukovic", "Marjanovic", "Crnkovic", "Stipic", "Grgic"],
		"male_syl": ["Iva", "Mar", "Luk", "Tom", "Ant", "Mar", "Dam", "Nik", "Jos", "Kre", "Zvo", "Bra", "Dom", "Stj", "Ved"],
		"female_syl": ["Ana", "Maj", "Iva", "Pet", "Mar", "Iva", "San", "Kri", "Nik", "Ant", "Luc", "Mir", "Ves", "Dor", "Tan"],
		"sur_roots": ["Horv", "Kov", "Bab", "Mar", "Tom", "Nov", "Jur", "Pet", "Blaz", "Kral", "Vuk", "Marj", "Crn", "Stip", "Grg"],
		"sur_end": ["at", "acevic", "ic", "ic", "ic", "ak", "ic", "ovic", "evic", "j"]
	},
	"Serbian": {
		"male_seeds": ["Novak", "Stefan", "Aleksandar", "Nikola", "Marko", "Milan", "Dusan", "Uros", "Luka", "Vuk", "Dragan", "Predrag", "Nemanja", "Danilo", "Bojan"],
		"female_seeds": ["Ana", "Jelena", "Milica", "Ivana", "Marija", "Maja", "Tamara", "Dragana", "Snezana", "Vesna", "Gordana", "Natasa", "Sanja", "Biljana", "Mirjana"],
		"surname_seeds": ["Djokovic", "Jovanovic", "Nikolic", "Petrovic", "Markovic", "Stojanovic", "Ilic", "Milosevic", "Popovic", "Arsenovic", "Lazarevic", "Stankovic", "Simic", "Mitrovic", "Todorovic"],
		"male_syl": ["Nov", "Ste", "Ale", "Nik", "Mar", "Mil", "Dus", "Uro", "Luk", "Vuk", "Dra", "Pre", "Nem", "Dan", "Boj"],
		"female_syl": ["Ana", "Jel", "Mil", "Iva", "Mar", "Maj", "Tam", "Dra", "Sne", "Ves", "Gor", "Nat", "San", "Bil", "Mir"],
		"sur_roots": ["Djok", "Jov", "Nikol", "Petr", "Mark", "Stoj", "Ilic", "Milos", "Pop", "Ars", "Laz", "Stank", "Sim", "Mitr", "Tod"],
		"sur_end": ["ovic", "anovic", "ic", "evic", "evic", "anovic", "ic", "evic", "ovic", "orovic"]
	},
	"Turkish": {
		"male_seeds": ["Cem", "Mert", "Berk", "Emre", "Kerem", "Burak", "Onur", "Sercan", "Erkan", "Tolga", "Yusuf", "Kaan", "Baran", "Deniz", "Alper"],
		"female_seeds": ["Elif", "Zeynep", "Ece", "Selin", "Buse", "Merve", "Naz", "Irem", "Dilara", "Arda", "Cansu", "Pinar", "Burcu", "Ayse", "Fatma"],
		"surname_seeds": ["Yilmaz", "Kaya", "Demir", "Sahin", "Celik", "Yildiz", "Yildirim", "Ozturk", "Aydin", "Ozdemir", "Arslan", "Dogan", "Kilic", "Aslan", "Koc"],
		"male_syl": ["Cem", "Mer", "Ber", "Emr", "Ker", "Bur", "Onu", "Ser", "Erk", "Tol", "Yus", "Kaa", "Bar", "Den", "Alp"],
		"female_syl": ["Eli", "Zey", "Ece", "Sel", "Bus", "Mer", "Naz", "Ire", "Dil", "Ard", "Can", "Pin", "Bur", "Ays", "Fat"],
		"sur_roots": ["Yilm", "Kay", "Dem", "Sah", "Cel", "Yild", "Ozt", "Ayd", "Ozd", "Arsl", "Dog", "Kil", "Asl", "Koc", "Ak"],
		"sur_end": ["az", "a", "ir", "in", "ik", "iz", "irim", "urk", "in", "an"]
	},
	"Russian": {
		"male_seeds": ["Vitaly", "Daniil", "Nikita", "Sergei", "Alexei", "Pavel", "Andrei", "Dmitri", "Ivan", "Maxim", "Artem", "Kirill", "Mikhail", "Vladimir", "Evgeny"],
		"female_seeds": ["Natasha", "Olga", "Svetlana", "Elena", "Irina", "Tatiana", "Anna", "Maria", "Ekaterina", "Daria", "Ksenia", "Anastasia", "Yulia", "Sofia", "Alexandra"],
		"surname_seeds": ["Petrov", "Sidorov", "Kuznetsov", "Popov", "Morozov", "Volkov", "Sokolov", "Kozlov", "Lebedev", "Novikov", "Fedorov", "Mikhailov", "Belov", "Orlov", "Makarov"],
		"male_syl": ["Vit", "Dan", "Nik", "Ser", "Ale", "Pav", "And", "Dmi", "Iva", "Max", "Art", "Kir", "Mik", "Vla", "Evg"],
		"female_syl": ["Nat", "Olg", "Sve", "Ele", "Iri", "Tat", "Ann", "Mar", "Eka", "Dar", "Kse", "Ana", "Jul", "Sof", "Ale"],
		"sur_roots": ["Petr", "Sid", "Kuzn", "Pop", "Mor", "Volk", "Sokol", "Kozl", "Leb", "Nov", "Fed", "Mikh", "Bel", "Orl", "Mak"],
		"sur_end": ["ov", "ev", "in", "ov", "ov", "ov", "ov", "ov", "ev", "ov"]
	},
	"Ukrainian": {
		"male_seeds": ["Sergiy", "Andriy", "Mykola", "Vasyl", "Oleksiy", "Bohdan", "Dmytro", "Yuriy", "Ihor", "Ruslan", "Taras", "Volodymyr", "Pavlo", "Maksym", "Denys"],
		"female_seeds": ["Olena", "Natalia", "Iryna", "Oksana", "Tetyana", "Yulia", "Svitlana", "Nataliya", "Hanna", "Larysa", "Mariya", "Inna", "Vira", "Lyudmyla", "Darya"],
		"surname_seeds": ["Kovalenko", "Bondarenko", "Tkachenko", "Kovalchuk", "Melnyk", "Shevchenko", "Petrenko", "Mykhalchuk", "Savchenko", "Sydorenko", "Marchenko", "Kovalev", "Ruban", "Pavlenko", "Lysenko"],
		"male_syl": ["Ser", "And", "Myk", "Vas", "Ole", "Boh", "Dmy", "Yur", "Iho", "Rus", "Tar", "Vol", "Pav", "Mak", "Den"],
		"female_syl": ["Ole", "Nat", "Iry", "Oks", "Tet", "Jul", "Svi", "Nat", "Han", "Lar", "Mar", "Inn", "Vir", "Lyu", "Dar"],
		"sur_roots": ["Koval", "Bond", "Tkach", "Kovalch", "Meln", "Shevch", "Petr", "Mykh", "Savch", "Syd", "March", "Koval", "Rub", "Pavl", "Lys"],
		"sur_end": ["enko", "arenko", "enko", "uk", "yk", "enko", "enko", "alchuk", "enko", "orenko"]
	},
	"Irish": {
		"male_seeds": ["Conor", "Liam", "Seamus", "Padraig", "Ciaran", "Eoin", "Fergus", "Declan", "Niall", "Ronan", "Brendan", "Cathal", "Donal", "Oisin", "Rory"],
		"female_seeds": ["Aoife", "Saoirse", "Niamh", "Ciara", "Orla", "Sinead", "Grainne", "Clodagh", "Aine", "Roisin", "Caoimhe", "Siobhan", "Deirdre", "Maeve", "Eilish"],
		"surname_seeds": ["Murphy", "Kelly", "OBrien", "Walsh", "Smith", "OSullivan", "McCarthy", "Byrne", "Ryan", "OConnor", "ONeill", "Doyle", "Reilly", "Quinn", "Gallagher"],
		"male_syl": ["Con", "Lia", "Sea", "Pad", "Cia", "Eoi", "Fer", "Dec", "Nia", "Ron", "Bre", "Cat", "Don", "Ois", "Ror"],
		"female_syl": ["Aoi", "Sao", "Nia", "Cia", "Orl", "Sin", "Gra", "Clo", "Ain", "Roi", "Cao", "Sio", "Dei", "Mae", "Eil"],
		"sur_roots": ["Murph", "Kell", "Bri", "Wals", "Smit", "Sull", "McCar", "Byrn", "Ryan", "Conn", "Neill", "Doyl", "Reill", "Quin", "Gallag"],
		"sur_end": ["y", "y", "en", "h", "h", "ivan", "thy", "e", "an", "or"]
	},
	"Scottish": {
		"male_seeds": ["Hamish", "Angus", "Alasdair", "Callum", "Fergus", "Fraser", "Duncan", "Ross", "Lachlan", "Malcolm", "Euan", "Iain", "Rory", "Craig", "Gregor"],
		"female_seeds": ["Fiona", "Isla", "Morag", "Catriona", "Eilidh", "Kirsty", "Mairi", "Shona", "Rhona", "Mhairi", "Ailsa", "Morven", "Kirsten", "Skye", "Heather"],
		"surname_seeds": ["MacDonald", "MacLeod", "Robertson", "Thomson", "Campbell", "Stewart", "Anderson", "MacKenzie", "Fraser", "Murray", "Reid", "MacLean", "Scott", "Morrison", "Grant"],
		"male_syl": ["Ham", "Ang", "Ala", "Cal", "Fer", "Fra", "Dun", "Ros", "Lac", "Mal", "Eua", "Iai", "Ror", "Cra", "Gre"],
		"female_syl": ["Fio", "Isl", "Mor", "Cat", "Eil", "Kir", "Mai", "Sho", "Rho", "Mha", "Ail", "Mor", "Kir", "Sky", "Hea"],
		"sur_roots": ["MacDon", "MacLe", "Robert", "Thom", "Campb", "Stew", "Anders", "MacKen", "Fras", "Murr", "Reid", "MacLe", "Scot", "Morr", "Gran"],
		"sur_end": ["ald", "od", "son", "son", "ell", "art", "on", "zie", "er", "ay"]
	},
	"Brazilian": {
		"male_seeds": ["Felipe", "Bruno", "Gabriel", "Rafael", "Thiago", "Lucas", "Matheus", "Gustavo", "Rodrigo", "Leonardo", "Fabio", "Renato", "Marcelo", "Eduardo", "Diego"],
		"female_seeds": ["Ana", "Julia", "Beatriz", "Larissa", "Gabriela", "Camila", "Fernanda", "Amanda", "Leticia", "Mariana", "Natalia", "Rafaela", "Isabela", "Vitoria", "Carolina"],
		"surname_seeds": ["Silva", "Santos", "Oliveira", "Souza", "Rodrigues", "Ferreira", "Alves", "Pereira", "Lima", "Gomes", "Costa", "Ribeiro", "Martins", "Carvalho", "Almeida"],
		"male_syl": ["Fel", "Bru", "Gab", "Raf", "Thi", "Luc", "Mat", "Gus", "Rod", "Leo", "Fab", "Ren", "Mar", "Edu", "Die"],
		"female_syl": ["Ana", "Jul", "Bea", "Lar", "Gab", "Cam", "Fer", "Ama", "Let", "Mar", "Nat", "Raf", "Isa", "Vit", "Car"],
		"sur_roots": ["Silv", "Sant", "Oliv", "Souz", "Rodr", "Ferr", "Alv", "Per", "Lim", "Gom", "Cost", "Rib", "Mart", "Carv", "Alm"],
		"sur_end": ["a", "os", "eira", "a", "es", "a", "es", "a", "a", "es"]
	},
	"American": {
		"male_seeds": ["Tyler", "Ryan", "Chase", "Austin", "Cole", "Hunter", "Logan", "Blake", "Cody", "Tanner", "Zach", "Kyle", "Brett", "Derek", "Shane"],
		"female_seeds": ["Emma", "Olivia", "Ava", "Isabella", "Sophia", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Abigail", "Emily", "Elizabeth", "Sofia", "Madison"],
		"surname_seeds": ["Andretti", "Allmendinger", "Newgarden", "Dixon", "Power", "Johnson", "Smith", "Williams", "Brown", "Jones", "Miller", "Davis", "Wilson", "Moore", "Taylor"],
		"male_syl": ["Tyl", "Rya", "Cha", "Aus", "Col", "Hun", "Log", "Bla", "Cod", "Tan", "Zac", "Kyl", "Bre", "Der", "Sha"],
		"female_syl": ["Emm", "Oli", "Ava", "Isa", "Sop", "Mia", "Cha", "Ame", "Har", "Eve", "Abi", "Emi", "Eli", "Sof", "Mad"],
		"sur_roots": ["And", "Allm", "Newg", "Dix", "Pow", "John", "Smit", "Will", "Brow", "Jon", "Mill", "Dav", "Wils", "Moor", "Tayl"],
		"sur_end": ["retti", "inger", "arden", "on", "er", "son", "h", "iams", "n", "es"]
	},
	"Canadian": {
		"male_seeds": ["Lance", "Nicholas", "Andre", "Patrick", "Marc", "Justin", "Olivier", "Felix", "Simon", "Alex", "Michael", "David", "Eric", "Nathan", "Daniel"],
		"female_seeds": ["Emma", "Olivia", "Sophia", "Charlotte", "Ava", "Mia", "Abigail", "Emily", "Madison", "Elizabeth", "Chloe", "Ella", "Grace", "Lily", "Aria"],
		"surname_seeds": ["Stroll", "Latifi", "Villeneuve", "Tremblay", "Gagnon", "Roy", "Cote", "Bouchard", "Morin", "Lavoie", "Fortin", "Gauthier", "Ouellet", "Bergeron", "Leblanc"],
		"male_syl": ["Lan", "Nic", "And", "Pat", "Mar", "Jus", "Oli", "Fel", "Sim", "Ale", "Mic", "Dav", "Eri", "Nat", "Dan"],
		"female_syl": ["Emm", "Oli", "Sop", "Cha", "Ava", "Mia", "Abi", "Emi", "Mad", "Eli", "Chl", "Ell", "Gra", "Lil", "Ari"],
		"sur_roots": ["Stro", "Lat", "Vill", "Tremb", "Gagn", "Roy", "Cot", "Bouch", "Mor", "Lav", "Fort", "Gauth", "Ouel", "Berg", "Leb"],
		"sur_end": ["ll", "ifi", "eneuve", "lay", "on", "e", "ard", "in", "oie", "lanc"]
	},
	"Mexican": {
		"male_seeds": ["Sergio", "Esteban", "Roberto", "Carlos", "Miguel", "Alejandro", "Jorge", "Antonio", "Fernando", "Ricardo", "Eduardo", "Arturo", "Emilio", "Raul", "Daniel"],
		"female_seeds": ["Sofia", "Valeria", "Isabella", "Camila", "Valentina", "Natalia", "Mariana", "Daniela", "Fernanda", "Andrea", "Gabriela", "Lucia", "Regina", "Paulina", "Ximena"],
		"surname_seeds": ["Perez", "Hernandez", "Garcia", "Martinez", "Lopez", "Gonzalez", "Rodriguez", "Ramirez", "Torres", "Flores", "Rivera", "Reyes", "Cruz", "Morales", "Gutierrez"],
		"male_syl": ["Ser", "Est", "Rob", "Car", "Mig", "Ale", "Jor", "Ant", "Fer", "Ric", "Edu", "Art", "Emi", "Rau", "Dan"],
		"female_syl": ["Sof", "Val", "Isa", "Cam", "Val", "Nat", "Mar", "Dan", "Fer", "And", "Gab", "Luc", "Reg", "Pau", "Xim"],
		"sur_roots": ["Per", "Hern", "Garc", "Mart", "Lop", "Gonz", "Rodr", "Ram", "Torr", "Flor", "Riv", "Rey", "Cru", "Mor", "Gut"],
		"sur_end": ["ez", "andez", "ia", "inez", "ez", "alez", "iguez", "irez", "es", "ierrez"]
	},
	"Argentinian": {
		"male_seeds": ["Franco", "Sebastian", "Agustin", "Marcos", "Nicolas", "Santiago", "Facundo", "Matias", "Ezequiel", "Gaston", "Leandro", "Federico", "Hernan", "Rodrigo", "Lucas"],
		"female_seeds": ["Valentina", "Florencia", "Camila", "Agustina", "Lucia", "Sofia", "Julieta", "Martina", "Catalina", "Micaela", "Rocio", "Melina", "Romina", "Celeste", "Antonella"],
		"surname_seeds": ["Gonzalez", "Rodriguez", "Fernandez", "Lopez", "Martinez", "Garcia", "Perez", "Sanchez", "Romero", "Sosa", "Torres", "Alvarez", "Ruiz", "Ramirez", "Flores"],
		"male_syl": ["Fra", "Seb", "Agu", "Mar", "Nic", "San", "Fac", "Mat", "Eze", "Gas", "Lea", "Fed", "Her", "Rod", "Luc"],
		"female_syl": ["Val", "Flo", "Cam", "Agu", "Luc", "Sof", "Jul", "Mar", "Cat", "Mic", "Roc", "Mel", "Rom", "Cel", "Ant"],
		"sur_roots": ["Gonz", "Rodr", "Fern", "Lop", "Mart", "Garc", "Per", "Sanch", "Rom", "Sos", "Torr", "Alv", "Rui", "Ram", "Flor"],
		"sur_end": ["alez", "iguez", "andez", "ez", "inez", "ia", "ez", "ez", "ero", "a"]
	},
	"Colombian": {
		"male_seeds": ["Juan", "Sebastian", "Esteban", "Carlos", "Andres", "Santiago", "Felipe", "Camilo", "Nicolas", "Daniel", "Alejandro", "David", "Jorge", "Miguel", "Luis"],
		"female_seeds": ["Sofia", "Valeria", "Isabella", "Camila", "Valentina", "Natalia", "Mariana", "Daniela", "Laura", "Andrea", "Gabriela", "Lucia", "Manuela", "Paula", "Juliana"],
		"surname_seeds": ["Gutierrez", "Gonzalez", "Rodriguez", "Garcia", "Lopez", "Martinez", "Hernandez", "Ramirez", "Sanchez", "Torres", "Vargas", "Castro", "Moreno", "Romero", "Jimenez"],
		"male_syl": ["Jua", "Seb", "Est", "Car", "And", "San", "Fel", "Cam", "Nic", "Dan", "Ale", "Dav", "Jor", "Mig", "Lui"],
		"female_syl": ["Sof", "Val", "Isa", "Cam", "Val", "Nat", "Mar", "Dan", "Lau", "And", "Gab", "Luc", "Man", "Pau", "Jul"],
		"sur_roots": ["Gut", "Gonz", "Rodr", "Garc", "Lop", "Mart", "Hern", "Ram", "Sanch", "Torr", "Varg", "Cast", "Mor", "Rom", "Jim"],
		"sur_end": ["ierrez", "alez", "iguez", "ia", "ez", "inez", "andez", "irez", "ez", "enez"]
	},
	"Chilean": {
		"male_seeds": ["Sebastien", "Cristobal", "Gonzalo", "Rodrigo", "Felipe", "Andres", "Pablo", "Diego", "Ignacio", "Matias", "Tomas", "Nicolas", "Benjamin", "Alejandro", "Francisco"],
		"female_seeds": ["Catalina", "Camila", "Sofia", "Valeria", "Fernanda", "Francisca", "Isidora", "Antonia", "Constanza", "Valentina", "Javiera", "Trinidad", "Natalia", "Gabriela", "Andrea"],
		"surname_seeds": ["Munoz", "Gonzalez", "Rojas", "Diaz", "Perez", "Soto", "Contreras", "Silva", "Martinez", "Sepulveda", "Morales", "Rodriguez", "Lopez", "Fuentes", "Hernandez"],
		"male_syl": ["Seb", "Cri", "Gon", "Rod", "Fel", "And", "Pab", "Die", "Ign", "Mat", "Tom", "Nic", "Ben", "Ale", "Fra"],
		"female_syl": ["Cat", "Cam", "Sof", "Val", "Fer", "Fra", "Isi", "Ant", "Con", "Val", "Jav", "Tri", "Nat", "Gab", "And"],
		"sur_roots": ["Mun", "Gonz", "Roj", "Di", "Per", "Sot", "Contr", "Silv", "Mart", "Sepulv", "Mor", "Rodr", "Lop", "Fuent", "Hern"],
		"sur_end": ["oz", "alez", "as", "az", "ez", "o", "eras", "a", "inez", "eda"]
	},
	"Venezuelan": {
		"male_seeds": ["Pastor", "Ernesto", "Carlos", "Luis", "Andres", "Ricardo", "Miguel", "Jose", "Antonio", "Francisco", "Alejandro", "Jorge", "Roberto", "Eduardo", "Sergio"],
		"female_seeds": ["Maria", "Sofia", "Valeria", "Gabriela", "Camila", "Isabella", "Daniela", "Fernanda", "Natalia", "Andrea", "Valentina", "Alejandra", "Carolina", "Monica", "Patricia"],
		"surname_seeds": ["Maldonado", "Gonzalez", "Rodriguez", "Garcia", "Martinez", "Lopez", "Hernandez", "Ramirez", "Sanchez", "Torres", "Perez", "Flores", "Romero", "Morales", "Castillo"],
		"male_syl": ["Pas", "Ern", "Car", "Lui", "And", "Ric", "Mig", "Jos", "Ant", "Fra", "Ale", "Jor", "Rob", "Edu", "Ser"],
		"female_syl": ["Mar", "Sof", "Val", "Gab", "Cam", "Isa", "Dan", "Fer", "Nat", "And", "Val", "Ale", "Car", "Mon", "Pat"],
		"sur_roots": ["Mald", "Gonz", "Rodr", "Garc", "Mart", "Lop", "Hern", "Ram", "Sanch", "Torr", "Per", "Flor", "Rom", "Mor", "Cast"],
		"sur_end": ["onado", "alez", "iguez", "ia", "inez", "ez", "andez", "irez", "ez", "illo"]
	},
	"Uruguayan": {
		"male_seeds": ["Nicolas", "Sebastian", "Gonzalo", "Martin", "Diego", "Federico", "Pablo", "Andres", "Matias", "Santiago", "Rodrigo", "Lucas", "Facundo", "Leandro", "Ignacio"],
		"female_seeds": ["Sofia", "Camila", "Valentina", "Lucia", "Florencia", "Natalia", "Agustina", "Carolina", "Mariana", "Daniela", "Victoria", "Romina", "Paola", "Celeste", "Jimena"],
		"surname_seeds": ["Rodriguez", "Gonzalez", "Garcia", "Fernandez", "Lopez", "Martinez", "Perez", "Sanchez", "Gomez", "Diaz", "Alvarez", "Torres", "Nunez", "Cabrera", "Suarez"],
		"male_syl": ["Nic", "Seb", "Gon", "Mar", "Die", "Fed", "Pab", "And", "Mat", "San", "Rod", "Luc", "Fac", "Lea", "Ign"],
		"female_syl": ["Sof", "Cam", "Val", "Luc", "Flo", "Nat", "Agu", "Car", "Mar", "Dan", "Vic", "Rom", "Pao", "Cel", "Jim"],
		"sur_roots": ["Rodr", "Gonz", "Garc", "Fern", "Lop", "Mart", "Per", "Sanch", "Gom", "Di", "Alv", "Torr", "Nun", "Cabr", "Suar"],
		"sur_end": ["iguez", "alez", "ia", "andez", "ez", "inez", "ez", "ez", "ez", "az"]
	},
	"Peruvian": {
		"male_seeds": ["Carlos", "Juan", "Luis", "Jorge", "Miguel", "Ricardo", "Alejandro", "Fernando", "Eduardo", "Andres", "Pablo", "Sebastian", "Diego", "Nicolas", "Rodrigo"],
		"female_seeds": ["Maria", "Sofia", "Valeria", "Camila", "Natalia", "Andrea", "Gabriela", "Isabella", "Daniela", "Fernanda", "Lucia", "Valentina", "Paola", "Monica", "Patricia"],
		"surname_seeds": ["Garcia", "Rodriguez", "Lopez", "Martinez", "Gonzalez", "Hernandez", "Perez", "Sanchez", "Torres", "Flores", "Ramirez", "Rivera", "Cruz", "Morales", "Reyes"],
		"male_syl": ["Car", "Jua", "Lui", "Jor", "Mig", "Ric", "Ale", "Fer", "Edu", "And", "Pab", "Seb", "Die", "Nic", "Rod"],
		"female_syl": ["Mar", "Sof", "Val", "Cam", "Nat", "And", "Gab", "Isa", "Dan", "Fer", "Luc", "Val", "Pao", "Mon", "Pat"],
		"sur_roots": ["Garc", "Rodr", "Lop", "Mart", "Gonz", "Hern", "Per", "Sanch", "Torr", "Flor", "Ram", "Riv", "Cru", "Mor", "Rey"],
		"sur_end": ["ia", "iguez", "ez", "inez", "alez", "andez", "ez", "ez", "es", "es"]
	},
	"Emirati": {
		"male_seeds": ["Mohammed", "Ahmed", "Khalid", "Sultan", "Hamdan", "Saeed", "Rashid", "Faisal", "Zayed", "Majid", "Tariq", "Omar", "Yousef", "Abdullah", "Hassan"],
		"female_seeds": ["Fatima", "Mariam", "Aisha", "Sara", "Hessa", "Latifa", "Shamma", "Maitha", "Noura", "Maryam", "Reem", "Dana", "Hind", "Shamsa", "Afra"],
		"surname_seeds": ["Al Maktoum", "Al Nahyan", "Al Rashidi", "Al Shamsi", "Al Mazrouei", "Al Falasi", "Al Kaabi", "Al Mansoori", "Al Dhaheri", "Al Nuaimi", "Al Qubaisi", "Al Suwaidi", "Al Mheiri", "Al Zaabi", "Al Hameli"],
		"male_syl": ["Moh", "Ahm", "Kha", "Sul", "Ham", "Sae", "Ras", "Fai", "Zay", "Maj", "Tar", "Uma", "You", "Abd", "Has"],
		"female_syl": ["Fat", "Mar", "Ais", "Sar", "Hes", "Lat", "Sha", "Mai", "Nou", "Mar", "Ree", "Dan", "Hin", "Sha", "Afr"],
		"sur_roots": ["Al Mak", "Al Nah", "Al Rash", "Al Sham", "Al Mazr", "Al Fal", "Al Kaa", "Al Mans", "Al Dhah", "Al Nua", "Al Qub", "Al Suw", "Al Mhe", "Al Zaa", "Al Ham"],
		"sur_end": ["toum", "yan", "idi", "si", "ouei", "asi", "bi", "oori", "eri", "imi"]
	},
	"Saudi": {
		"male_seeds": ["Mohammed", "Abdullah", "Faisal", "Khalid", "Sultan", "Turki", "Bandar", "Saud", "Majed", "Tariq", "Waleed", "Nasser", "Mansour", "Fahad", "Ibrahim"],
		"female_seeds": ["Fatima", "Sara", "Norah", "Hessa", "Reema", "Lujain", "Maha", "Reem", "Arwa", "Lina", "Shahad", "Dina", "Alanoud", "Rana", "Ghada"],
		"surname_seeds": ["Al Saud", "Al Rashid", "Al Qahtani", "Al Ghamdi", "Al Zahrani", "Al Shehri", "Al Otaibi", "Al Harbi", "Al Dosari", "Al Maliki", "Al Shahrani", "Al Yami", "Al Bishi", "Al Ahmadi", "Al Mutairi"],
		"male_syl": ["Moh", "Abd", "Fai", "Kha", "Sul", "Tur", "Ban", "Sau", "Maj", "Tar", "Wal", "Nas", "Man", "Fah", "Ibr"],
		"female_syl": ["Fat", "Sar", "Nor", "Hes", "Ree", "Luj", "Mah", "Ree", "Arw", "Lin", "Sha", "Din", "Ala", "Ran", "Gha"],
		"sur_roots": ["Al Sa", "Al Rash", "Al Qaht", "Al Gham", "Al Zahr", "Al Sheh", "Al Ota", "Al Har", "Al Dos", "Al Mal", "Al Shah", "Al Yam", "Al Bis", "Al Ahm", "Al Mut"],
		"sur_end": ["ud", "id", "ani", "di", "ani", "ri", "bi", "bi", "ari", "iki"]
	},
	"Lebanese": {
		"male_seeds": ["Georges", "Pierre", "Michel", "Antoine", "Elie", "Tony", "Charbel", "Rami", "Karim", "Samer", "Tarek", "Ziad", "Wissam", "Rabih", "Fady"],
		"female_seeds": ["Nadia", "Rania", "Maya", "Lara", "Celine", "Nadine", "Carla", "Rita", "Christine", "Sandra", "Joelle", "Isabelle", "Stephanie", "Nicole", "Pamela"],
		"surname_seeds": ["Khoury", "Haddad", "Nassar", "Azar", "Frem", "Gemayel", "Salam", "Jumblatt", "Berri", "Aoun", "Hariri", "Geagea", "Murr", "Tueni", "Rahbani"],
		"male_syl": ["Geo", "Pie", "Mic", "Ant", "Eli", "Ton", "Cha", "Ram", "Kar", "Sam", "Tar", "Zia", "Wis", "Rab", "Fad"],
		"female_syl": ["Nad", "Ran", "May", "Lar", "Cel", "Nad", "Car", "Rit", "Chr", "San", "Joe", "Isa", "Ste", "Nic", "Pam"],
		"sur_roots": ["Khou", "Hadd", "Nass", "Azar", "Frem", "Gemay", "Salam", "Jumbl", "Berr", "Aou", "Harir", "Geag", "Murr", "Tuen", "Rahb"],
		"sur_end": ["ry", "ad", "ar", "ar", "em", "el", "am", "att", "i", "n"]
	},
	"Moroccan": {
		"male_seeds": ["Mohammed", "Youssef", "Hamza", "Amine", "Karim", "Mehdi", "Rachid", "Omar", "Khalid", "Hassan", "Soufiane", "Ayoub", "Nabil", "Samir", "Tariq"],
		"female_seeds": ["Fatima", "Khadija", "Amina", "Nadia", "Sara", "Salma", "Houda", "Meriem", "Zineb", "Samira", "Laila", "Hind", "Btissam", "Ikram", "Asma"],
		"surname_seeds": ["Benali", "El Idrissi", "Benhaddou", "Amrani", "Chraibi", "Bensouda", "El Alami", "Tazi", "Fassi", "Berrada", "El Hassani", "Benkirane", "Lahlou", "Kettani", "Ziani"],
		"male_syl": ["Moh", "You", "Ham", "Ami", "Kar", "Meh", "Rac", "Uma", "Kha", "Has", "Sou", "Ayo", "Nab", "Sam", "Tar"],
		"female_syl": ["Fat", "Kha", "Ami", "Nad", "Sar", "Sal", "Hou", "Mer", "Zin", "Sam", "Lai", "Hin", "Bti", "Ikr", "Asm"],
		"sur_roots": ["Ben", "El Id", "Benhad", "Amr", "Chra", "Bensou", "El Al", "Taz", "Fass", "Berr", "El Has", "Benkir", "Lahlo", "Kett", "Ben"],
		"sur_end": ["ali", "rissi", "dou", "ani", "ibi", "da", "ami", "i", "i", "ada"]
	},
	"South African": {
		"male_seeds": ["Jody", "Deon", "Nico", "Darryl", "Warren", "Kyle", "Kelvin", "Shaun", "Trevor", "Brett", "Liam", "Andre", "Pieter", "Hendrik", "Christoff"],
		"female_seeds": ["Emma", "Sophia", "Olivia", "Mia", "Ava", "Isabella", "Charlotte", "Amelia", "Lerato", "Thandi", "Nomsa", "Zanele", "Palesa", "Harper", "Evelyn"],
		"surname_seeds": ["Van der Merwe", "Botha", "Pretorius", "Steenkamp", "Du Plessis", "Van Zyl", "Cronje", "Nel", "Engelbrecht", "De Villiers", "Fourie", "Venter", "Smit", "Coetzee", "Potgieter"],
		"male_syl": ["Jod", "Deo", "Nic", "Dar", "War", "Kyl", "Kel", "Sha", "Tre", "Bre", "Lia", "And", "Pie", "Hen", "Chr"],
		"female_syl": ["Emm", "Sop", "Oli", "Mia", "Ava", "Isa", "Cha", "Ame", "Ler", "Tha", "Nom", "Zan", "Pal", "Har", "Eve"],
		"sur_roots": ["Both", "Pretor", "Steenk", "Du Pless", "Van Z", "Cron", "Nel", "Engelb", "De Vill", "Four", "Vent", "Smit", "Coetz", "Potg", "Viss"],
		"sur_end": ["a", "ius", "amp", "is", "yl", "je", "", "recht", "iers", "er"]
	},
	"Egyptian": {
		"male_seeds": ["Mohamed", "Ahmed", "Omar", "Khaled", "Tamer", "Sherif", "Amr", "Hassan", "Karim", "Mahmoud", "Mostafa", "Youssef", "Tarek", "Hossam", "Adel"],
		"female_seeds": ["Nour", "Sara", "Mariam", "Hana", "Rana", "Dina", "Yasmine", "Salma", "Rania", "Mona", "Amira", "Noha", "Eman", "Ghada", "Heba"],
		"surname_seeds": ["Hassan", "Ibrahim", "Mahmoud", "Ahmed", "Ali", "Mohamed", "Saad", "Khalil", "Nasser", "Mansour", "Farouk", "Rashid", "Mostafa", "Sayed", "Hamdi"],
		"male_syl": ["Moh", "Ahm", "Uma", "Kha", "Tam", "She", "Amr", "Has", "Kar", "Mah", "Mos", "You", "Tar", "Hos", "Ade"],
		"female_syl": ["Nou", "Sar", "Mar", "Han", "Ran", "Din", "Yas", "Sal", "Ran", "Mon", "Ami", "Noh", "Ema", "Gha", "Heb"],
		"sur_roots": ["Has", "Ibr", "Mahm", "Ahm", "Ali", "Moh", "Saa", "Khal", "Nass", "Mans", "Far", "Rash", "Most", "Say", "Ham"],
		"sur_end": ["san", "ahim", "oud", "ed", "i", "amed", "d", "il", "er", "di"]
	},
	"Qatari": {
		"male_seeds": ["Mohammed", "Abdullah", "Hamad", "Jassim", "Khalid", "Sultan", "Ali", "Ahmad", "Nasser", "Saad", "Tamim", "Faleh", "Turki", "Meshal", "Fahad"],
		"female_seeds": ["Fatima", "Mariam", "Aisha", "Hessa", "Noora", "Shaikha", "Moza", "Sheikha", "Reem", "Dana", "Lolwah", "Asma", "Amna", "Wadha", "Maryam"],
		"surname_seeds": ["Al Thani", "Al Kuwari", "Al Sulaiti", "Al Marri", "Al Hajri", "Al Naimi", "Al Mohannadi", "Al Attiyah", "Al Emadi", "Al Ansari", "Al Jaber", "Al Khater", "Al Nuaimi", "Al Malki", "Al Buainain"],
		"male_syl": ["Moh", "Abd", "Ham", "Jas", "Kha", "Sul", "Ali", "Ahm", "Nas", "Saa", "Tam", "Fal", "Tur", "Mes", "Fah"],
		"female_syl": ["Fat", "Mar", "Ais", "Hes", "Noo", "Sha", "Moz", "She", "Ree", "Dan", "Lol", "Asm", "Amn", "Wad", "May"],
		"sur_roots": ["Al Th", "Al Kuw", "Al Sul", "Al Mar", "Al Haj", "Al Nai", "Al Moh", "Al Att", "Al Em", "Al Ans", "Al Jab", "Al Khat", "Al Nua", "Al Mal", "Al Bua"],
		"sur_end": ["ani", "ari", "aiti", "ri", "ri", "mi", "annadi", "iyah", "adi", "inain"]
	},
	"Kuwaiti": {
		"male_seeds": ["Mohammed", "Abdullah", "Hamad", "Jaber", "Khalid", "Nawaf", "Ahmad", "Nasser", "Fahad", "Faisal", "Mishari", "Bader", "Talal", "Saud", "Turki"],
		"female_seeds": ["Fatima", "Sara", "Nour", "Hessa", "Reem", "Dana", "Lulwa", "Sheikha", "Maha", "Noura", "Asma", "Shahad", "Alanoud", "Ghada", "Sundus"],
		"surname_seeds": ["Al Sabah", "Al Rashidi", "Al Mutairi", "Al Ajmi", "Al Shimmari", "Al Enezi", "Al Otaibi", "Al Dosari", "Al Azmi", "Al Kandari", "Al Sayed", "Al Hamad", "Al Farsi", "Al Mansouri", "Al Bloushi"],
		"male_syl": ["Moh", "Abd", "Ham", "Jab", "Kha", "Naw", "Ahm", "Nas", "Fah", "Fai", "Mis", "Bad", "Tal", "Sau", "Tur"],
		"female_syl": ["Fat", "Sar", "Nou", "Hes", "Ree", "Dan", "Lul", "She", "Mah", "Nou", "Asm", "Sha", "Ala", "Gha", "Sun"],
		"sur_roots": ["Al Sa", "Al Rash", "Al Mut", "Al Ajm", "Al Shimm", "Al En", "Al Ota", "Al Dos", "Al Azm", "Al Kand", "Al Say", "Al Ham", "Al Far", "Al Mans", "Al Blo"],
		"sur_end": ["bah", "idi", "airi", "i", "ari", "ezi", "ibi", "ari", "i", "ushi"]
	},
	"Japanese": {
		"male_seeds": ["Yuki", "Kazuki", "Ryo", "Takuma", "Naoki", "Hiroshi", "Kenji", "Satoshi", "Daisuke", "Kohei", "Ryota", "Shota", "Kenta", "Yuji", "Makoto"],
		"female_seeds": ["Yuki", "Hana", "Sakura", "Aoi", "Rin", "Mio", "Saki", "Nana", "Yuna", "Mei", "Haruka", "Kana", "Risa", "Mika", "Yui"],
		"surname_seeds": ["Tsunoda", "Suzuki", "Nakajima", "Kobayashi", "Sato", "Tanaka", "Watanabe", "Ito", "Yamamoto", "Nakamura", "Hayashi", "Yoshida", "Matsumoto", "Inoue", "Kato"],
		"male_syl": ["Yuk", "Kaz", "Ryo", "Tak", "Nao", "Hir", "Ken", "Sat", "Dai", "Koh", "Ryo", "Sho", "Ken", "Yuj", "Mak"],
		"female_syl": ["Yuk", "Han", "Sak", "Aoi", "Rin", "Mio", "Sak", "Nan", "Yun", "Mei", "Har", "Kan", "Ris", "Mik", "Yui"],
		"sur_roots": ["Tsun", "Suzuk", "Nakaj", "Kobay", "Sat", "Tanak", "Watanab", "It", "Yamamot", "Nakamur", "Hayash", "Yoshid", "Matsumot", "Inou", "Kat"],
		"sur_end": ["oda", "i", "ima", "ashi", "o", "a", "e", "o", "o", "o"]
	},
	"Chinese": {
		"male_seeds": ["Wei", "Lei", "Ming", "Jian", "Hao", "Yang", "Peng", "Fei", "Chen", "Long", "Xiao", "Jun", "Tao", "Bin", "Cheng"],
		"female_seeds": ["Li", "Na", "Fang", "Ying", "Yan", "Xin", "Hui", "Jing", "Ling", "Mei", "Xue", "Rong", "Qian", "Zhen", "Lan"],
		"surname_seeds": ["Wang", "Li", "Zhang", "Liu", "Chen", "Yang", "Huang", "Zhao", "Wu", "Zhou", "Xu", "Sun", "Ma", "Hu", "Zhu"],
		"male_syl": ["Wei", "Lei", "Min", "Jia", "Hao", "Yan", "Pen", "Fei", "Che", "Lon", "Xia", "Jun", "Tao", "Bin", "Che"],
		"female_syl": ["Li", "Na", "Fan", "Yin", "Yan", "Xin", "Hui", "Jin", "Lin", "Mei", "Xue", "Ron", "Qia", "Zhe", "Lan"],
		"sur_roots": ["Wang", "Li", "Zhan", "Liu", "Che", "Yan", "Huan", "Zhao", "Wu", "Zhou", "Xu", "Sun", "Ma", "Hu", "Zhu"],
		"sur_end": ["g", "i", "g", "u", "n", "g", "g", "u", "u", "u"]
	},
	"South Korean": {
		"male_seeds": ["Minjun", "Seojun", "Dohyun", "Jiwoo", "Junho", "Hyunwoo", "Jaehyun", "Sungmin", "Taehyun", "Woojin", "Kyungjun", "Donghyun", "Sanghoon", "Yongjun", "Jihoon"],
		"female_seeds": ["Jiyeon", "Soyeon", "Minji", "Yuna", "Seoyeon", "Hayeon", "Jiwon", "Somin", "Hyejin", "Nayeon", "Chaeyeon", "Dahyun", "Yeeun", "Seulgi", "Irene"],
		"surname_seeds": ["Kim", "Lee", "Park", "Choi", "Jung", "Kang", "Cho", "Yoon", "Jang", "Lim", "Han", "Oh", "Seo", "Shin", "Kwon"],
		"male_syl": ["Min", "Seo", "Doh", "Jiw", "Jun", "Hyu", "Jae", "Sun", "Tae", "Woo", "Kyu", "Don", "San", "Yon", "Jih"],
		"female_syl": ["Jiy", "Soy", "Min", "Yun", "Seo", "Hay", "Jiw", "Som", "Hye", "Nay", "Cha", "Dah", "Yee", "Seu", "Ire"],
		"sur_roots": ["Kim", "Lee", "Park", "Cho", "Jun", "Kan", "Cho", "Yoo", "Jan", "Lim", "Han", "Oh", "Seo", "Shin", "Kwon"],
		"sur_end": ["m", "e", "k", "i", "g", "g", "o", "n", "g", "h"]
	},
	"Australian": {
		"male_seeds": ["Jack", "Liam", "Noah", "Oliver", "William", "James", "Lucas", "Mason", "Ethan", "Daniel", "Oscar", "Thomas", "Archie", "Charlie", "Henry"],
		"female_seeds": ["Olivia", "Charlotte", "Ava", "Mia", "Amelia", "Grace", "Isla", "Ella", "Sophie", "Chloe", "Lily", "Harper", "Zoe", "Ruby", "Emma"],
		"surname_seeds": ["Smith", "Jones", "Williams", "Brown", "Wilson", "Taylor", "Johnson", "White", "Martin", "Anderson", "Thompson", "Davis", "Robinson", "Clark", "Mitchell"],
		"male_syl": ["Jac", "Lia", "Noa", "Oli", "Wil", "Jam", "Luc", "Mas", "Eth", "Dan", "Osc", "Tho", "Arc", "Cha", "Hen"],
		"female_syl": ["Oli", "Cha", "Ava", "Mia", "Ame", "Gra", "Isl", "Ell", "Sop", "Chl", "Lil", "Har", "Zoe", "Rub", "Emm"],
		"sur_roots": ["Smit", "Jon", "Willi", "Brow", "Wils", "Tayl", "John", "Whit", "Mart", "Anders", "Thomp", "Dav", "Robin", "Clar", "Mitch"],
		"sur_end": ["h", "es", "ams", "n", "on", "or", "son", "e", "in", "ell"]
	},
	"Indian": {
		"male_seeds": ["Arjun", "Rishi", "Kush", "Virat", "Rohan", "Aditya", "Rahul", "Vikram", "Sanjay", "Rajesh", "Prateek", "Nikhil", "Ankit", "Suresh", "Dhruv"],
		"female_seeds": ["Priya", "Ananya", "Divya", "Pooja", "Neha", "Aisha", "Kavya", "Sneha", "Riya", "Simran", "Nisha", "Shruti", "Pallavi", "Meera", "Tara"],
		"surname_seeds": ["Sharma", "Patel", "Singh", "Kumar", "Mehta", "Gupta", "Joshi", "Malhotra", "Kapoor", "Verma", "Bose", "Chatterjee", "Iyer", "Nair", "Reddy"],
		"male_syl": ["Arj", "Ris", "Kus", "Vir", "Roh", "Adi", "Rah", "Vik", "San", "Raj", "Pra", "Nik", "Ank", "Sur", "Dhr"],
		"female_syl": ["Pri", "Ana", "Div", "Poo", "Neh", "Ais", "Kav", "Sne", "Riy", "Sim", "Nis", "Shr", "Pal", "Mee", "Tar"],
		"sur_roots": ["Sharm", "Pat", "Sin", "Kum", "Meht", "Gupt", "Josh", "Malhotr", "Kapoo", "Verm", "Bos", "Chatt", "Iy", "Nai", "Redd"],
		"sur_end": ["a", "el", "gh", "ar", "a", "a", "i", "a", "r", "y"]
	},
	"Thai": {
		"male_seeds": ["Nattawut", "Thanatip", "Voravut", "Peerapat", "Kantapon", "Chanapol", "Saravut", "Jirawat", "Kittipat", "Thitipong", "Atthaphon", "Supachai", "Wanchai", "Pakorn", "Ronnachai"],
		"female_seeds": ["Natthida", "Chanoknan", "Siriporn", "Pornpimol", "Warunee", "Supalak", "Rattana", "Nattaya", "Pimchanok", "Wilasinee", "Saranya", "Kultida", "Pornthip", "Nareerat", "Benjawan"],
		"surname_seeds": ["Srichai", "Wongpan", "Kamolrat", "Tantirangsi", "Sukhum", "Promthong", "Phongphan", "Rattanakorn", "Charoenwong", "Boonsong", "Suwannakorn", "Pattanapong", "Siriphan", "Wattana", "Thongchai"],
		"male_syl": ["Nat", "Tha", "Vor", "Pee", "Kan", "Cha", "Sar", "Jir", "Kit", "Thi", "Att", "Sup", "Wan", "Pak", "Ron"],
		"female_syl": ["Nat", "Cha", "Sir", "Por", "War", "Sup", "Rat", "Nat", "Pim", "Wil", "Sar", "Kul", "Por", "Nar", "Ben"],
		"sur_roots": ["Sri", "Wong", "Kamol", "Tant", "Sukh", "Prom", "Phong", "Rattan", "Charoen", "Boon", "Suwan", "Pattan", "Sirip", "Watt", "Thong"],
		"sur_end": ["chai", "pan", "rat", "irangsi", "um", "thong", "phan", "akorn", "wong", "song"]
	},
	"Malaysian": {
		"male_seeds": ["Azlan", "Faizal", "Hafizuddin", "Khairul", "Mukhriz", "Nabil", "Rahman", "Syafiq", "Tengku", "Wan", "Zahir", "Amirul", "Firdaus", "Haziq", "Izwan"],
		"female_seeds": ["Aishah", "Farah", "Haslinda", "Izzati", "Khairunnisa", "Liyana", "Nadia", "Rashidah", "Siti", "Ummi", "Warda", "Yasmin", "Zulaikha", "Balqis", "Dalila"],
		"surname_seeds": ["Abdullah", "Ahmad", "Ali", "Hassan", "Ibrahim", "Ismail", "Karim", "Mahmud", "Mohamed", "Mustafa", "Rahman", "Rashid", "Salleh", "Yusof", "Zainuddin"],
		"male_syl": ["Azl", "Fai", "Haf", "Kha", "Muk", "Nab", "Rah", "Sya", "Ten", "Wan", "Zah", "Ami", "Fir", "Haz", "Izw"],
		"female_syl": ["Ais", "Far", "Has", "Izz", "Kha", "Liy", "Nad", "Ras", "Sit", "Umm", "War", "Yas", "Zul", "Bal", "Dal"],
		"sur_roots": ["Abd", "Ahm", "Ali", "Has", "Ibr", "Ism", "Kar", "Mahm", "Moh", "Must", "Rahm", "Rash", "Sall", "Yus", "Zain"],
		"sur_end": ["ullah", "ad", "i", "san", "rahim", "ail", "im", "ud", "amed", "uddin"]
	},
	"Indonesian": {
		"male_seeds": ["Bimo", "Dimas", "Eko", "Fajar", "Galih", "Hendra", "Irfan", "Joko", "Kevin", "Lutfi", "Mamat", "Nanda", "Oscar", "Pandu", "Rizky"],
		"female_seeds": ["Ayu", "Bella", "Citra", "Dewi", "Eka", "Fitri", "Gita", "Hana", "Indah", "Jihan", "Kirana", "Laras", "Maya", "Nisa", "Putri"],
		"surname_seeds": ["Santoso", "Wijaya", "Suharto", "Kusuma", "Prasetyo", "Nugroho", "Hidayat", "Gunawan", "Halim", "Setiawan", "Wahyu", "Purwanto", "Susanto", "Hartono", "Wibowo"],
		"male_syl": ["Bim", "Dim", "Eko", "Faj", "Gal", "Hen", "Irf", "Jok", "Kev", "Lut", "Mam", "Nan", "Osc", "Pan", "Riz"],
		"female_syl": ["Ayu", "Bel", "Cit", "Dew", "Eka", "Fit", "Git", "Han", "Ind", "Jih", "Kir", "Lar", "May", "Nis", "Put"],
		"sur_roots": ["Sant", "Wij", "Suhart", "Kusum", "Praset", "Nugr", "Hiday", "Gunaw", "Hal", "Setiaw", "Wah", "Purw", "Sus", "Harton", "Wib"],
		"sur_end": ["oso", "aya", "o", "a", "o", "oho", "at", "an", "im", "owo"]
	},
	"New Zealander": {
		"male_seeds": ["Liam", "Noah", "Oliver", "Jack", "James", "William", "Mason", "Ethan", "Lucas", "Logan", "Oscar", "Finn", "Archie", "Charlie", "Hunter"],
		"female_seeds": ["Olivia", "Charlotte", "Isla", "Ava", "Mia", "Amelia", "Grace", "Sophie", "Ruby", "Harper", "Zoe", "Ella", "Lily", "Chloe", "Emma"],
		"surname_seeds": ["Smith", "Jones", "Williams", "Brown", "Taylor", "Wilson", "Johnson", "White", "Martin", "Thompson", "Anderson", "Robinson", "Clark", "Mitchell", "Walker"],
		"male_syl": ["Lia", "Noa", "Oli", "Jac", "Jam", "Wil", "Mas", "Eth", "Luc", "Log", "Osc", "Fin", "Arc", "Cha", "Hun"],
		"female_syl": ["Oli", "Cha", "Isl", "Ava", "Mia", "Ame", "Gra", "Sop", "Rub", "Har", "Zoe", "Ell", "Lil", "Chl", "Emm"],
		"sur_roots": ["Smit", "Jon", "Willi", "Brow", "Tayl", "Wils", "John", "Whit", "Mart", "Thomp", "Anders", "Robin", "Clar", "Mitch", "Walk"],
		"sur_end": ["h", "es", "ams", "n", "or", "on", "son", "e", "in", "er"]
	},
	"Catalan": {
		"male_seeds": ["Marc", "Pol", "Arnau", "Oriol", "Pau", "Biel", "Guillem", "Jordi", "Lluc", "Miquel", "Nil", "Roger", "Sergi", "Toni", "Xavi"],
		"female_seeds": ["Laia", "Mar", "Neus", "Ona", "Aina", "Carla", "Claudia", "Emma", "Julia", "Laura", "Marta", "Nuria", "Paula", "Sara", "Sofia"],
		"surname_seeds": ["Garcia", "Martinez", "Lopez", "Gonzalez", "Fernandez", "Puig", "Mas", "Bosch", "Vidal", "Ferrer", "Pons", "Soler", "Roca", "Serra", "Sala"],
		"male_syl": ["Mar", "Pol", "Arn", "Ori", "Pau", "Bie", "Gui", "Jor", "Llu", "Miq", "Nil", "Rog", "Ser", "Ton", "Xav"],
		"female_syl": ["Lai", "Mar", "Neu", "Ona", "Ain", "Car", "Cla", "Emm", "Jul", "Lau", "Mar", "Nur", "Pau", "Sar", "Sof"],
		"sur_roots": ["Garc", "Mart", "Lop", "Gonz", "Fern", "Pui", "Mas", "Bos", "Vid", "Ferr", "Pon", "Sol", "Roc", "Serr", "Sal"],
		"sur_end": ["ia", "inez", "ez", "alez", "andez", "g", "s", "ch", "al", "a"]
	},
	"Basque": {
		"male_seeds": ["Iker", "Unai", "Mikel", "Aitor", "Jon", "Gorka", "Asier", "Benat", "Eneko", "Gaizka", "Julen", "Kepa", "Leire", "Oier", "Xabier"],
		"female_seeds": ["Ane", "Amaia", "Itziar", "Leire", "Nerea", "Olatz", "Maider", "Uxue", "Ainhoa", "Garazi", "Izaro", "Jone", "Karmele", "Nahia", "Oihane"],
		"surname_seeds": ["Etxeberria", "Garitano", "Iriarte", "Larrea", "Mendizabal", "Olaizola", "Zabala", "Aguirre", "Azkue", "Bilbao", "Elorza", "Goikoetxea", "Ibarretxe", "Lazkano", "Urrutia"],
		"male_syl": ["Ike", "Una", "Mik", "Ait", "Jon", "Gor", "Asi", "Ben", "Ene", "Gai", "Jul", "Kep", "Lei", "Oie", "Xab"],
		"female_syl": ["Ane", "Ama", "Itz", "Lei", "Ner", "Ola", "Mai", "Uxu", "Ain", "Gar", "Iza", "Jon", "Kar", "Nah", "Oih"],
		"sur_roots": ["Etxe", "Garit", "Iriar", "Larr", "Mendiz", "Olaiz", "Zabal", "Aguir", "Azku", "Bilb", "Elor", "Goiko", "Ibarr", "Lazk", "Urr"],
		"sur_end": ["berria", "ano", "te", "ea", "abal", "ola", "a", "re", "e", "utia"]
	},
	"Luxembourgish": {
		"male_seeds": ["Nicolas", "Alex", "Patrick", "Marc", "Tom", "Ben", "Felix", "Max", "Simon", "Jan", "Luca", "Noah", "Elias", "Leon", "Lukas"],
		"female_seeds": ["Emma", "Lea", "Sophie", "Laura", "Anna", "Julia", "Sarah", "Marie", "Lisa", "Clara", "Hannah", "Lena", "Mia", "Nina", "Lara"],
		"surname_seeds": ["Weber", "Schmit", "Klein", "Becker", "Wagner", "Muller", "Meyer", "Braun", "Hoffmann", "Koch", "Schneider", "Fischer", "Zimmermann", "Richter", "Wolf"],
		"male_syl": ["Nic", "Ale", "Pat", "Mar", "Tom", "Ben", "Fel", "Max", "Sim", "Jan", "Luc", "Noa", "Eli", "Leo", "Luk"],
		"female_syl": ["Emm", "Lea", "Sop", "Lau", "Ann", "Jul", "Sar", "Mar", "Lis", "Cla", "Han", "Len", "Mia", "Nin", "Lar"],
		"sur_roots": ["Web", "Schm", "Klei", "Beck", "Wagn", "Mull", "Mey", "Brau", "Hoff", "Koch", "Schneid", "Fisch", "Zimm", "Richt", "Wolf"],
		"sur_end": ["er", "it", "n", "er", "er", "er", "er", "n", "mann", "er"]
	},
	"Flemish": {
		"male_seeds": ["Stef", "Wout", "Jasper", "Pieter", "Jens", "Wouter", "Sander", "Lander", "Kobe", "Bram", "Arne", "Dries", "Joren", "Niels", "Tibo"],
		"female_seeds": ["Julie", "Emma", "Lore", "Amber", "Elien", "Ines", "Nathalie", "An", "Hanne", "Tine", "Silke", "Katrien", "Griet", "Sofie", "Lies"],
		"surname_seeds": ["De Smedt", "Peeters", "Janssen", "Maes", "Jacobs", "Claes", "Stevens", "Willems", "Leclercq", "Vermeersch", "Desmet", "Nijs", "Bogaert", "Claeys", "Declercq"],
		"male_syl": ["Ste", "Wou", "Jas", "Pie", "Jen", "Wou", "San", "Lan", "Kob", "Bra", "Arn", "Dri", "Jor", "Nie", "Tib"],
		"female_syl": ["Jul", "Emm", "Lor", "Amb", "Eli", "Ine", "Nat", "An", "Han", "Tin", "Sil", "Kat", "Gri", "Sof", "Lie"],
		"sur_roots": ["De Sme", "Peet", "Jans", "Mae", "Jac", "Cla", "Stev", "Wille", "Lecl", "Vermeer", "Desm", "Nij", "Bogaer", "Claey", "Decl"],
		"sur_end": ["dt", "ers", "sen", "s", "obs", "s", "ens", "ms", "ercq", "ercq"]
	},
	"Welsh": {
		"male_seeds": ["Rhys", "Owain", "Gareth", "Gethin", "Huw", "Rhodri", "Llyr", "Emyr", "Iwan", "Geraint", "Alun", "Ceri", "Dafydd", "Eifion", "Guto"],
		"female_seeds": ["Sian", "Rhiannon", "Megan", "Bethan", "Cerys", "Nia", "Angharad", "Catrin", "Elen", "Ffion", "Gwenno", "Haf", "Lowri", "Manon", "Non"],
		"surname_seeds": ["Jones", "Williams", "Davies", "Evans", "Thomas", "Roberts", "Hughes", "Lewis", "Morgan", "Griffiths", "Edwards", "Owen", "Price", "Phillips", "Rees"],
		"male_syl": ["Rhy", "Owa", "Gar", "Get", "Huw", "Rho", "Lly", "Emy", "Iwa", "Ger", "Alu", "Cer", "Daf", "Eif", "Gut"],
		"female_syl": ["Sia", "Rhi", "Meg", "Bet", "Cer", "Nia", "Ang", "Cat", "Ele", "Ffi", "Gwe", "Haf", "Low", "Man", "Non"],
		"sur_roots": ["Jon", "Willi", "Dav", "Evan", "Thom", "Rob", "Hugh", "Lew", "Morg", "Griff", "Edw", "Owen", "Pric", "Phill", "Rees"],
		"sur_end": ["es", "ams", "ies", "s", "as", "erts", "es", "is", "an", "iths"]
	}
}

func _ready() -> void:
	print("[NameData] Loaded %d nationalities" % data.size())
