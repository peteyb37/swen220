/*
 * Types of toys.
 */
mtype = { DOLL, TRAIN, BALL } ;

/*
 * How many toys of each type are required.
 */
#define NDOLLS  3
#define NTRAINS 3
#define NBALLS  2

/*
 * Global counts of the number of each toy made by the elves.
 */
byte doll_count = 0 ;
byte train_count = 0 ;
byte ball_count = 0 ;

/*
 * Number of elves and maximum number of toys required from each.
 */
#define NELVES  3 
#define NTOYS   3

/*
 * In addition to toy names, these are messages that can be sent.
 *     NEXT_TOY & LEAVING: Elf to Santa
 *     NO_MORE_TOYS:       Santa to elf.
 */
mtype = { NEXT_TOY, NO_MORE_TOYS, LEAVING } ;

/*
 * Channel for messages from elves to Santa.
 */
chan to_santa = [2] of { mtype, byte, chan } ;

/*
 * Flag set true when Santa exits.
 */
bool done = false ;

/*
 * Elf process - parameter is a zero-based id.
 */
proctype Elf(byte id) {
	byte numToys = 0 ;
	
	chan from_santa = [1] of { mtype } ;
	mtype response ;
	
	printf("Elf %d arrives for work.\n", id) ;
	
	do
	::  if
		::  numToys >= NTOYS -> 
				break ;
		::  else ->
				printf("Elf %d asks Santa what to do.\n", id) ;
				
				to_santa ! NEXT_TOY(id, from_santa) ;
				
				from_santa ? response ;
				
				if
				::  response == NO_MORE_TOYS ->
						break ;
				::  else ->
						printf("Elf %d makes a %e.\n", id, response) ;
						numToys++ ;
						to_santa ! response(id, from_santa) ;
				fi ;
		fi ;
	od ;

	printf("Elf %d leaves having made %d toys.\n", id, numToys) ;
	to_santa ! LEAVING(id, from_santa) ;
}

/*
 * Santa process.
 */
proctype Santa() {
	byte elvesGone = 0 ;
	byte numTrains = 0 ;
	byte numDolls = 0 ;
	byte numBalls = 0 ;
	mtype assigned[NELVES] ;
	byte id ;
	mtype ToySelected ;
	chan from_santa ;
	mtype response ;
	byte n = 0 ;
	
	printf("Santa arrives at the toy shop.\n") ;
	do
	::  if
		::  elvesGone >= NELVES ->
				break ;
		::  else ->
				to_santa ? response(id, from_santa) ;
				if
				::  response == TRAIN ->
						assert assigned[id] == TRAIN ;
						printf("Santa records elf %d made a %e.\n", id, response) ;
						numTrains-- ;
						train_count++ ;
				::  response == BALL ->
						assert assigned[id] == BALL ;
						printf("Santa records elf %d made a %e.\n", id, response) ;
						numBalls-- ;
						ball_count++ ;
				::  response == DOLL ->
						assert assigned[id] == DOLL ;
						printf("Santa records elf %d made a %e.\n", id, response) ;
						numDolls-- ;
						doll_count++ ;
				::  response == LEAVING ->
						printf("Santa notes elf %d has departed.\n", id) ;
						elvesGone++ ;
				::  response == NEXT_TOY ->
						if
						:: (numTrains + train_count) < NTRAINS ->
								numTrains++ ;
								ToySelected = TRAIN ;
						:: (numBalls + ball_count) < NBALLS ->
								numBalls++ ;
								ToySelected = BALL ;
						:: (numDolls + doll_count) < NDOLLS ->
								numDolls++ ;
								ToySelected = DOLL ;
						:: else ->
							ToySelected = NO_MORE_TOYS ;
						fi ;
						
						assigned[id] = ToySelected ;

						if
						:: ToySelected == NO_MORE_TOYS ->
							printf("Santa tells elf %d that there are no more toys to be made.\n", id) ;
						:: else ->
							printf("Santa assigns elf %d a %e.\n", id, ToySelected) ;
						fi ;
						from_santa ! ToySelected ;

				fi ;
				
	
		fi ;
	od ;	


	printf("Santa closes shop with %d dolls, %d trains, %d balls made.\n", doll_count, train_count, ball_count) ;
	done = true ;
	

}

/*
 * System initialization.
 */
init {
    byte elf = 0 ;

    /*
     * Start the elves and Santa.
     */
    atomic {
        do
        :: elf >= NELVES ->
            break ;
        :: else ->
            run Elf(elf) ;
            elf++ ;
        od ;
        run Santa() ;
    }
}

/*
    It is always the case that the number of dolls, trains, and balls
    made is less than or equal to the number required.
*/
ltl Safe {
	[](doll_count <= NDOLLS && ball_count <= NBALLS && train_count <= NTRAINS) ;
}

/*
    Eventually the system will be in a state where the
    all elves and Santa have terminated (e.g., done is true).
*/
ltl Completion {
	<>(done == true) ;
}

/*
    Eventually the system is at a state where the the
    correct number of dolls, trains, and balls have been made.
*/
ltl Correctness {
	<>(doll_count == NDOLLS && ball_count == NBALLS && train_count == NTRAINS) ;
}
