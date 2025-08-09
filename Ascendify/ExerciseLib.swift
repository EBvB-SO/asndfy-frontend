//
//  ExerciseLib.swift
//  Ascendify
//
//  Created by Ellis Barker on 13/02/2025.
//

import SwiftUI

struct ExerciseLib: View {
    // MARK: - EXERCISE DATA
    // Now each category has a 'description' providing an overview.
    let categories: [ExerciseCategory] = [
        
        // MARK: - Aero Cap
        
        ExerciseCategory(
            name: "Aerobic Capacity",
            icon: "lungs",
            description: """
Aerobic Capacity is your ability to climb at a low-to-moderate intensity for extended durations. 

It's crucial for long sport or trad routes where sustained effort is needed with minimal rests. 

Training aerobic capacity helps you delay the onset of pump and recover more efficiently on easier terrain and faster when on good holds.
""",
            exercises: [
                Exercise(
                    name: "Continuous Low-Intensity Climbing",
                    benefits: """
Builds your aerobic base, fosters efficient movement under mild fatigue and teaches your body to recover efficiently whilst on the wall.
Best for: endurance routes, recovery sessions, base building
""",
                    equipment: """
Best perfomed on a circuit board or on a slightly overhanging boulder wall with many holds to move around on. This can be also be effectively performed on a lead wall with downclimbing and a willing belayer. Additionally, an auto-belay can be a useful tool when performing this exercise.
""",
                    details: """
Stay on the wall continuously for 20-40 minutes at a comfortably easy grade. Focus on smooth technique, controlled breathing and minimal rest on holds. This trains low-intensity stamina and improves movement efficiency.
""",
                    example: """
Move around continuously for 30 minute maintaining a very low level of pump.
"""
                ),
                Exercise(
                    name: "Mixed Intensity Laps",
                    benefits: """
Improves aerobic capacity by alternating moderate climbing with low intensity climbing.
Best for: endurance routes, base building, training efficiency
""",
                    equipment: """
Best perfomed on a circuit board but can be effectively performed on a lead wall.
""",
                    details: """
Choose a route/circuit with an easy manageable difficulty, around 6-8 grades below your maximum onsight grade with ~30-40 moves alongside a route/circuit which is around your onsight level and a similar length. 
Climb half of the easy route before switching into the second half of the more difficult route, completing 30-40 moves in total. This is one rep. 
Rest for 8-12 minutes before repeating for for 2-4 reps.
""",
                    example: """
A 6c onsight climber should perform the first half on a 5b route before moving into a 6c route for the second half of the rep.
"""
                ),
                Exercise(
                    name: "X-On, X-Off Intervals",
                    benefits: """
Improves aerobic capacity by alternating moderate climbing with rest.
Best for: endurance routes, base building, training efficiency
""",
                    equipment: """
Circuit board, boulder wall, lead wall or auto-belay wall.                    
""",
                    details: """
Climb for a set time (e.g., 10 minutes) at a moderate intensity, then rest for the same duration (10 minutes). Repeat 3-4 times. Maintain consistent pace and focus on good footwork to maximize benefits.
""",
                    example: """
A climber who regularly climbs 7a can use a circuit around 6b and climb continuously for 10 minutes, maintaining a steady pace without getting severely pumped. After resting for 10 minutes, they repeat the process 3 more times, focusing on perfect technique and breathing control throughout each interval.
"""
                ),
                Exercise(
                    name: "Route 4x4s",
                    benefits: """
Improves sustained endurance and mental resilience for longer routes.
Best for: endurance routes, redpoint preparation, stamina building
""",
                    equipment: """
Best performed using a circuit board or lead wall.
""",
                    details: """
Pick a route you can climb comfortably when fresh. Lead it 4 times in a row with minimal rest between attempts—just enough to re-tie or chalk up. Focus on efficient movement and pacing to handle the pump.
""",
                    example: """
A climber who can onsight 7c should select a route or selection of routes around 7a. The climber should climb the routes back to back with minimal rest in between. The climber should avoid resting in one position for too long and focus on keeping a good consistent rhythm throughout the set.
"""
                ),
                Exercise(
                    name: "Linked Laps",
                    benefits: """
Builds base endurance by stacking multiple climbs into one session.
Best for: pumpy sport routes, trad routes
""",
                    equipment:"""
Circuit board, lead wall, or auto-belay wall. Multiple established routes of similar difficulty.                
""",
                    details: """
How to do it:
Climb a moderate route, lower off, shake for ~1 minute, then climb again. Do 2-3 back-to-back laps. Keep rests short to simulate continuous effort. Choose a difficulty that challenges you but allows multiple laps.
""",
                    example: """
A climber who onsights 6c should select three 6a/6a+ routes. After warming up, they climb the first route, lower off, rest for precisely 60 seconds while chalking up and shaking out, then immediately climb the second route. After another brief 60-second rest, they climb the third route. This completes one set. After resting 8-10 minutes, they perform another 1-2 sets depending on fatigue levels.
"""
                ),
                Exercise(
                    name: "Low Intensity Fingerboarding",
                    benefits: """
Builds forearm endurance.
Best for: endurance routes, forearm endurance, route climbers
""",
                    equipment: """
Equipment Required:
Fingerboard or a singular campus rung. Use of a pulley will usually be required to reduce intensity.
""",
                    details: """
How to do it:
Using 30-40% of your maximum hang, complete a 7 second hang, followed by 3 seconds of rest, continue this cycle for 10-16 reps. This should be repeated for 6-10 sets with 1 minute of rest between each set.
The level of pump should be low to moderate.
""",
                    example: """
Example Session:
A climber weighing 60kg who has a 2 arm max hang with an added 20kg should use a pulley with 24kg. The climber would then compete 10 sets of 7:3 repeaters.   
"""
                ),
                Exercise(
                    name: "Foot-On Campus Endurance",
                    benefits: """
Builds forearm endurance and core stability.
Best for: endurance routes, forearm endurance, route climbers
""",
                    equipment: """
Campus board with low rungs or footholds. The campus board should have a variety of rung sizes to allow for intensity adjustments.
""",
                    details: """
How to do it:
Use a campus board but keep your feet on lower rungs or small footholds. Move steadily for 5-10 minutes at a time, minimizing rests. Aim to keep continuous movement or very brief pauses to maintain tension.
""",
                    example: """
A climber starts with feet on the lowest campus board rung and hands on medium-sized holds (20-25mm). They move up and down the board continuously for 7 minutes, keeping feet engaged on the footholds and focusing on controlled hand movements. The workout includes 3 sets of 7 minutes with 5 minutes rest between sets. The level of pump should be moderate but sustainable throughout each set.
"""
                )
            ]
        ),
        
        // MARK: - An Cap

        ExerciseCategory(
            name: "Anaerobic Capacity",
            icon: "flame",
            description: """
Anaerobic Capacity is the ability to sustain a higher intensity output (near or above your aerobic threshold) for moderate durations. 

It's key for pumpy routes or bouldery sections where you have to fight lactic acid buildup. 

Training anaerobic capacity helps you keep climbing even when you're running out of air and power.
""",
            exercises: [
                Exercise(
                    name: "Long Boulder Circuits",
                    benefits: """
Builds the ability to fight the pump during intense, longer sequences.
Best for: sustained crux sequences, power-endurance routes
""",
                    equipment: """
Boulder wall or circuit board with a variety of hold types. Ideally a slightly overhanging wall (10-20 degrees) with a good mix of crimps, slopers, and pinches.
""",
                    details: """
How to do it:
Set or find 12-15 move boulder problems or link sections on a training wall. Climb with effort, then rest 2-4 times the climbing duration. Aim for 8-10 total repetitions. Expect lactic buildup; fight through it with good technique.
""",
                    example: """
A climber who can flash V6 (7A) should create a 15-move circuit at around V4 (6B+) difficulty. They climb the circuit with high intensity, taking about 45-60 seconds to complete. After each repetition, they rest for 2-3 minutes, then repeat for a total of 8 repetitions. The circuit should feel increasingly challenging as fatigue builds, requiring concentration to maintain technique through the pump.
"""
                ),
                Exercise(
                    name: "Boulder Triples",
                    benefits: """
Develops the ability to climb short routes, longer boulders and through cruxes.
Best for: routes with back-to-back cruxes, power endurance routes with bouldery sections
""",
                    equipment: """
Boulder wall with problems of appropriate difficulty. Training board or gym with a variety of established boulder problems close to each other for efficient transitions.
""",
                    details: """
How to do it:
Choose three challenging boulder problems around 6-8 moves long, each roughly at your flash grade. For each set, climb one boulder three times in succession, resting exactly 60 seconds between repetitions and 3 minutes between sets, completing a total of 6 sets (two per boulder). Aim to feel powered-out but not pumped; adjust the difficulty if consistently falling early, or increase it if all repetitions feel easy. Incorporate variety by selecting problems with different climbing styles and holds.
""",
                    example: """
A climber who flashes V5 (6C) should select three V5 boulder problems with different styles - one crimpy, one with slopers, and one with dynamic moves. They climb the first problem three times with precisely 60 seconds rest between attempts, rest 3 minutes, then repeat the same pattern with the second and third problems. The complete workout includes 9 climbs (3 on each of the 3 problems), with the goal of completing all attempts with good form despite increasing fatigue.
"""
                ),
                Exercise(
                    name: "Linked Bouldering Circuits",
                    benefits: """
Develops the ability to link multiple cruxes back to back.
Best for: routes with back-to-back cruxes, endurance routes with bouldery sections

""",
                    equipment: """
Boulder wall with multiple problems in close proximity. Circuit board or systems wall can also work well for setting custom problems.
""",
                    details: """
How to do it:
String together 2-3 boulder problems in one go. Avoid resting on the ground between them. This replicates the fatigue of encountering successive bouldery sections on a route, honing stamina and power under pump.
""",
                    example: """
A climber links together a V3 (6A), V4 (6B+), and V2 (5C) problem in sequence without touching the ground between problems. The sequence requires downclimbing or traversing between each problem to stay on the wall. They complete 4 sets of this linked circuit with 4-5 minutes rest between sets. Each linked sequence should take 2-3 minutes to complete and generate significant pump by the final problem.
"""
                ),
                Exercise(
                    name: "Campus Laddering",
                    benefits: """
Improves upper-body pulling power and lactic tolerance for steep climbs.
Best for: powerful routes, steep climbing, dynamic movement
Priority: Medium
""",
                    equipment: """
Campus board with a variety of rung sizes. Medium-sized rungs (20-25mm) are ideal for most climbers, though beginners may need larger holds.
""",
                    details: """
How to do it:
Use a campus board to move hand-over-hand up and down 15-20 moves per set. Rest 2-3 minutes between sets and do 8-10 sets total. Keep movements powerful but controlled; avoid flailing or straining shoulders.
""",
                    example: """
A climber starts with both hands on the lowest rung. They move their right hand up to the next rung, then left hand up, continuing this alternating pattern to the top of the board (about 8 moves up). At the top, they reverse the process to climb back down, completing about 16 moves total. After resting 2-3 minutes, they repeat for a total of 8 sets, focusing on controlled, powerful movements and proper shoulder engagement throughout each repetition.
"""
                ),
                Exercise(
                    name: "Fingerboard Repeater Blocks",
                    benefits: """
Develops forearm endurance under moderate-high load on small edges.
Best for: crimpy routes, small holds, finger strength endurance
""",
                    equipment: """
Hangboard/fingerboard with various edge sizes. A weight belt or pulley system for adding or removing weight as needed.
""",
                    details: """
How to do it:
On a fingerboard, perform 4 consecutive hangs of ~7 seconds on / 3 seconds off as one "block." Rest 2-3 minutes, then repeat 3-5 blocks. Choose an edge size or added weight that challenges you but stays safe.
""",
                    example: """
A climber selects a 20mm edge on the fingerboard and uses a half-crimp grip position. They perform 4 consecutive hangs (7 seconds on, 3 seconds off) without coming off the board between hangs. After completing this "block" of 4 hangs, they rest for 2-3 minutes, then repeat for a total of 4 blocks. The edge size should be challenging enough that the final hang in each block feels difficult but completable with good form. For advanced climbers, adding weight or using smaller edges (15mm) can increase intensity.
"""
                ),
                Exercise(
                    name: "Multiple Set Boulder Circuits",
                    benefits: """
Trains your capacity to handle repeated hard sequences with partial recovery.
Best for: hard redpoint sequences, bouldery sport routes
""",
                    equipment: """
Boulder wall with established problems or circuit board for creating custom sequences. Problems should be within your capability but challenging.
""",
                    details: """
How to do it:
Design a short circuit of linked boulder problems. Climb 4-5 repetitions, rest 10-20 minutes, then repeat 2-3 times. Focus on hitting quality attempts, learning movement efficiency as fatigue sets in.
""",
                    example: """
A climber designs a circuit of 3 linked boulder problems (V4-V5 range) totaling about 20-25 moves. They climb this circuit 4 times with 3 minutes rest between attempts. After completing these 4 repetitions, they take a longer 15-minute rest, then repeat the entire process twice more. Throughout the workout, they focus on maintaining good technique even as fatigue builds, and they note how their climbing efficiency changes over the course of the session. The entire workout includes 12 high-quality attempts at the circuit.
"""
                ),
                Exercise(
                    name: "Density Hangs",
                    benefits: """
Builds forearm pump tolerance for routes with sparse rests.
Best for: pumpy routes with poor rests
""",
                    equipment: """
Fingerboard, jugs on a systems wall, or large holds on a campus board. A timer for precise measurement of hang and rest intervals.
""",
                    details: """
How to do it:
On a fingerboard or good holds on the wall, hang for longer durations (20-40 seconds) at a moderately difficult load. Rest briefly and repeat. Focus on forearm engagement and safe shoulder posture while pumped.
""",
                    example: """
A climber selects medium-sized holds or 25-30mm edges on a fingerboard. They hang for 30 seconds, rest for 30 seconds, and repeat for 6-8 cycles. The intensity should be challenging enough that significant pump builds up by the 3rd or 4th hang, but not so difficult that they can't complete the full duration of each hang. Focus remains on breathing through the pump and maintaining engaged shoulders throughout each hang. For progression, rest intervals can be gradually reduced to 20 seconds while keeping hang time constant.
"""
                )
            ]
        ),
        
        // MARK: - Aero Cap
        
        ExerciseCategory(
            name: "Aerobic Power",
            icon: "bolt",
            description: """
Aerobic Power is about climbing at moderately high intensity for longer durations without resting, bridging the gap between purely aerobic (easy) and purely anaerobic (very hard) efforts.

Essential for routes where you need to maintain a tough pace without immediate pump failure.
""",
            exercises: [
                Exercise(
                    name: "30-Move Circuits",
                    benefits: """
Builds power-endurance for sustained, pumpy routes.
Best for: sustained sport routes, power-endurance, onsighting
""",
                    equipment: """
Circuit board, boulder wall with adjacent problems, or lead wall with established routes. Setting a specific circuit with colored holds can be ideal for this exercise.
""",
                    details: """
How to do it:
Create a 30-move circuit on a training wall or link multiple problems without rests or shake-outs. Climb the sequence, rest 1-2 times your climbing time, and repeat. Focus on continuous movement and efficient footwork.
""",
                    example: """
A climber creates a 30-move circuit at about 70-80% of their maximum difficulty (for a 7c climber, around 7a-7b). The circuit takes approximately 2-3 minutes to complete and generates significant pump by the end. After completion, they rest for 4-5 minutes, then repeat the circuit for a total of 4-5 repetitions. Each attempt should feel challenging but completable, with the final 10 moves requiring focus and technique to battle through the pump.
"""
                ),
                Exercise(
                    name: "On-The-Minute Bouldering",
                    benefits: """
Develops the ability to repeatedly perform short, powerful sequences with minimal rest.
Best for: sustained climbing, power-endurance, recovering quickly between cruxes
""",
                    equipment: """
Boulder wall with established problems of appropriate difficulty. A timer or clock for precise one-minute intervals.
""",
                    details: """
How to do it:
Choose a short, ~6-8 move boulder problem. Start one attempt every minute on the minute (EMOM) for 8 total reps. Rest briefly in the remaining time each minute. Increase or decrease difficulty/rest as needed.
""",
                    example: """
A climber who can flash V5 (6C) selects a V3 (6A) boulder problem with about 7 moves. Using a timer, they begin climbing at 0:00, complete the problem in about 20-30 seconds, and use the remaining 30-40 seconds to rest before starting again at precisely 1:00. This pattern continues for 8 consecutive minutes. By the 5th or 6th repetition, the rest period will feel increasingly inadequate, forcing the climber to recover quickly and climb efficiently even when fatigued. If they can complete all 8 repetitions, they can increase difficulty for the next session.
"""
                ),
                Exercise(
                    name: "Boulder 4x4s",
                    benefits: """
Great for building power-endurance across multiple back-to-back problems.
Best for: power-endurance routes, sustained cruxes, competition preparation
""",
                    equipment: """
Boulder wall with 4 established problems in close proximity to each other. Problems should be below your maximum ability but challenging enough to create fatigue when linked.
""",
                    details: """
How to do it:
Pick 4 boulder problems around your onsight or just below your limit. Climb them back-to-back with minimal rest. Then rest 1-3 minutes and repeat the entire 4-problem circuit a total of 4 times.
""",
                    example: """
A climber who can redpoint V7 (7A+) selects four V4-V5 (6B+-6C) problems in different styles. They climb the first problem, immediately downclimb or jump down and move to the second problem, continuing until all four problems are completed with no rest between them. After finishing the fourth problem, they rest for 2 minutes, then repeat the entire circuit again. This is repeated for a total of 4 rounds (16 total problems climbed). By the final round, significant pump should have built up, challenging the climber to maintain good technique and efficient movement.
"""
                ),
                Exercise(
                    name: "3x3 Bouldering Circuits",
                    benefits: """
Great for short, powerful routes or boulders with limited rest.
Best for: hard boulders, short routes with multiple cruxes
""",
                    equipment: """
Boulder wall with established problems of appropriate difficulty. Problems should be spaced close enough to transition quickly between them.
""",
                    details: """
How to do it:
Select 3 boulder problems at a challenging level. Climb each problem 3 times in a row with minimal rest, then rest more thoroughly and move to the next problem. This trains sustained power for multiple crux attempts.
""",
                    example: """
A climber who can send V6 (7A) selects three V4 (6B+) problems with different styles - one crimpy, one with slopers, and one with dynamic moves. They climb the first problem three times in succession with only 15-20 seconds rest between attempts. After completing the third repetition, they rest for 3 minutes, then move to the second problem and repeat the same pattern. After completing all three problems (9 total climbs), they've completed one full 3x3 circuit. For advanced climbers, this can be repeated twice in a session with 8-10 minutes rest between complete circuits.
"""
                ),
                Exercise(
                    name: "Intensive Foot-On Campus",
                    benefits: """
Focuses on forearm pump management in steep terrain.
Best for: steep sport routes, severe pump management, forearm endurance
""",
                    equipment: """
Campus board with a variety of rung sizes and footholds. For beginners, larger rungs (30mm+) are recommended, while advanced climbers can use medium rungs (20-25mm).
""",
                    details: """
How to do it:
On a campus board, keep your feet on small rungs or designated footholds. Climb up and down for about 1 minute, then rest 1-2 minutes. Complete 8 reps total, aiming for continuous movement under pump.
""",
                    example: """
A climber starts with feet on the lowest campus board rung and hands on medium-sized holds. They move continuously up and down the campus board for 1 minute, keeping feet on the footholds throughout. The pace should be moderately fast but controlled, generating significant forearm pump by the end of the minute. After resting for 90 seconds, they repeat for a total of 8 one-minute intervals. The intensity should be calibrated so that completing the final 10-15 seconds of each interval requires focus and determination to fight through the pump.
"""
                )
            ]
        ),
        
        // MARK: - An Pow
        
        ExerciseCategory(
            name: "Anaerobic Power",
            icon: "bolt.circle",
            description: """
Anaerobic Power is your ability to produce near-maximal force for short durations, think powerful cruxes or short boulder sections on a route. 

Crucial for sequences that require big pulls or explosive moves on small holds without immediate rests.
""",
            exercises: [
                Exercise(
                    name: "Short Boulder Repeats",
                    benefits: """
Boosts power for hard cruxes with minimal rest for partial recovery adaptation.
Best for: bouldery routes, hard crux sequences, dynamic moves
""",
                    equipment: """
Boulder wall with established problems near your maximum ability. Problems should be short (5-7 moves) and powerful rather than technical or endurance-based.
""",
                    details: """
How to do it:
Select a ~5-7 move boulder problem near your max. Climb it 4 times with rest equal to or less than climbing time. Complete 4 total sets, resting about 10 minutes between each set. Focus on explosive, precise movement.
""",
                    example: """
A climber who can send V7 (7A+) selects a powerful V6 (7A) boulder problem with 6 moves. They climb the problem, which takes about 30 seconds to complete, then rest for exactly 30 seconds before attempting again. They complete 4 attempts with this 1:1 work-to-rest ratio, then rest for 10 minutes before repeating the process for a total of 4 sets (16 total attempts). Each attempt should be executed with maximum intensity and precision, even as fatigue builds throughout the set. The long rest between sets allows for sufficient recovery to maintain high quality in each set.
"""
                ),
                Exercise(
                    name: "Broken Circuits",
                    benefits: """
Improves linking multiple power-intensive sections with limited rest.
Best for: linking hard sections, redpoint preparation, power-endurance
""",
                    equipment: """
Circuit board or boulder wall where you can create a continuous sequence of about 25 moves. The wall angle should match your project or target climbing style.
""",
                    details: """
How to do it:
Create a ~25-move circuit and break it into 3-4 sections. Climb each section quickly with minimal rest between sections. Over time, reduce the rests to simulate one long near-limit effort.
""",
                    example: """
A climber designs a 25-move circuit at about 80% of their maximum difficulty and divides it into 4 sections of 6-7 moves each. Initially, they climb each section with 15 seconds rest between sections. After completing the full circuit, they rest 5 minutes and repeat twice more. In subsequent sessions, they gradually reduce the rest between sections to 10 seconds, then 5 seconds, and eventually climb the entire circuit without breaks. This progression simulates the process of linking difficult sequences on a project route, teaching the body to recover quickly during brief moments between intense efforts.
"""
                ),
                Exercise(
                    name: "Max Intensity Redpoints",
                    benefits: """
Builds high-end power and mental fortitude for pushing limits.
Best for: crux sequences, competition preparation, mental training
""",
                    equipment: """
Lead wall with routes at your maximum ability, or boulder wall with long problems/circuits that challenge your absolute limit. A patient belayer for lead climbing.
""",
                    details: """
How to do it:
Work on a ~20-30 move route or circuit at your absolute limit. Attempt full redpoints with proper rest (10+ minutes) between tries. Focus on precise beta, power, and mental game to push through the crux.
""",
                    example: """
A climber projects a route or boulder circuit at their absolute limit (e.g., a climber who redpoints 7c+ working on an 8a route). After thorough warming up, they make a full redpoint attempt, giving 100% effort and focus. Whether successful or not, they rest for at least 12-15 minutes between attempts to ensure near-complete recovery. During each rest period, they mentally rehearse the beta and visualize successful execution. They make 3-4 total attempts in a session, with each attempt being a genuine maximal effort that requires both physical power and mental focus to push through difficult sequences. This exercise develops both physical capacity and the mental skills needed for successful redpointing.
"""
                )
            ]
        ),
        
        // MARK: - Finger Strength
        
        ExerciseCategory(
            name: "Finger Strength",
            icon: "hand.pinch.fill",
            description: """
Finger strength refers to your maximal force output of the fingers, particularly on small holds. 

Developing finger-strength is very climbing specific and is essential for harder boulders and routes, especially when pulling and moving between small holds.
""",
            exercises: [
                Exercise(
                    name: "Fingerboard Max Hangs (Crimps)",
                    benefits: """
Increases maximal finger strength on small holds with added load.
Best for: small hold cruxes, bouldery routes, crimpy routes
Priority: High
""",
                    equipment: """
Hangboard/fingerboard with various edge sizes (typically 15-20mm edges for training). Weight belt, weight vest or pulley system for adding load.
""",
                    details: """
How to do it:
Choose a small edge or add weight so that a 10-second hang is near your limit. After each hang, rest fully (2-3 minutes). Perform 5-8 total hangs. Maintain shoulder engagement and good form to prevent injury.
""",
                    example: """
A climber selects a 20mm edge on the fingerboard and adds enough weight (via weight belt or vest) that they can just barely complete a 10-second hang with perfect form. They perform the hang with a half-crimp grip position, maintaining engaged shoulders and proper body position throughout. After completing the hang, they rest for 2-3 minutes to ensure complete recovery, then repeat for a total of 6 hangs. Throughout the session, they focus on quality over quantity, maintaining perfect form for each hang and adjusting weight if necessary to keep the intensity at approximately 90-95% of maximum. The workout is completed in about 20 minutes total.
"""
                ),
                Exercise(
                    name: "Fingerboard Max Hangs (Pockets)",
                    benefits: """
Increases maximal finger strength on pockets with added load.
Best for: pockety cruxes, bouldery routes, pockety routes
Priority: High
""",
                    equipment: """
Hangboard/fingerboard with various edge sizes and/or pockets (typically 15-20mm edges for training). Weight belt, weight vest or pulley system for adding load.
""",
                    details: """
How to do it:
Choose a small or edge/pocket, add weight so that a 10-second hang is near your limit. After each hang, rest fully (2-3 minutes). Perform 5-8 total hangs. Maintain shoulder engagement and good form to prevent injury.
    If the route you are focussed on uses mainly 2 finger pockets then focus on this for training. Similarly if the route focusses on 3 finger pockets, selecting a 3 finger pocket or drag on an edge would be prefereable.
""",
                    example: """
A climber selects a 15mm 2 finger pocket on the fingerboard due to trying a route in Frankenjura with a crux involving multiple moves on 2 finger pockets. The climber then adds enough weight (via weight belt or vest) that they can just barely complete a 10-second hang with perfect form. They perform the hang with a drag grip position, maintaining engaged shoulders and proper body position throughout. After completing the hang, they rest for 2-3 minutes to ensure complete recovery, then repeat for a total of 6 hangs. Throughout the session, they focus on quality over quantity, maintaining perfect form for each hang and adjusting weight if necessary to keep the intensity at approximately 90-95% of maximum. The workout is completed in about 20 minutes total.
"""
                ),
                Exercise(
                    name: "Dead Hangs",
                    benefits: """
Fundamental grip exercise that boosts finger and grip strength.
Best for: all climbing styles
Priority: Medium
""",
                    equipment: """
Hangboard, pull-up bar, or campus rungs of various sizes. For beginners, larger holds (30mm+) are appropriate, while advanced climbers may use smaller edges (15-20mm).
""",
                    details: """
How to do it:
Simply hang on a pull-up bar, jugs or fingerboard edges for ~20-30 seconds. Rest briefly and repeat for multiple sets. Keep shoulders active (slightly engaged) and avoid sloppy form.
""",
                    example: """
A climber selects appropriate holds based on their level - beginners might use a pull-up bar or large jugs, while advanced climbers might use 20mm edges. They hang for 30 seconds with engaged shoulders and proper body position, rest for 90 seconds, and repeat for a total of 5 sets. Focus remains on quality rather than pushing to failure, with each hang maintained with perfect form. For progression, edge size can be decreased or hang time increased, but form should never be compromised. This exercise can be performed 2-3 times per week as part of a regular training routine.
"""
                ),
            ]
        ),
        
        // MARK: - Strength
        
        ExerciseCategory(
            name: "Strength",
            icon: "bolt.circle.fill",
            description: """
Strength refers to your maximal force output, especially on big moves and the ability to lock deep between holds.
 
Developing climbing-specific strength is essential for harder boulders, overhanging routes and powerful pulling.
""",
            exercises: [
                Exercise(
                    name: "Max Boulder Sessions",
                    benefits: """
Improves maximum bouldering strength and technique under full-rest conditions.
Best for: short powerful problems, short powerful routes, power endurance routes
""",
                    equipment: """
Boulder wall with problems at or near your maximum ability. Good quality crash pads and spotters for safety when working hard problems.
""",
                    details: """
How to do it:
Work on your hardest boulder problems with full rest (3-5 minutes) between tries. Emphasize precision and maximum effort. Stop if you notice a drop in quality due to fatigue; the goal is true max power.
""",
                    example: """
A climber selects 2-3 boulder problems at their absolute limit (or 1-2 grades above their current level). They attempt each problem with full focus and intensity, resting 3-5 minutes between attempts. After 2-3 attempts on one problem, they switch to another problem to maintain motivation and engagement. The session focuses on quality over quantity, with perhaps only 12-15 total attempts across all problems. Each attempt should be preceded by visualization and mental preparation, treating each try as a performance rather than practice. The session ends when the climber notices a drop in power output or focus, typically after 60-90 minutes of climbing time.
"""
                ),
                Exercise(
                    name: "Board Session",
                    benefits: """
Improves maximum strength and power on specific move types.
Best for: steep climbing, powerful routes, competition preparation
""",
                    equipment: """
Climbing board such as a Moon Board, Kilter Board, or Tension Board. These standardized training boards allow for consistent difficulty progression.
""",
                    details: """
How to do it:
Start with easier boulder problems on the board as a warm-up, then progressively increase the difficulty through a total of 10 problems. Focus on quality attempts with full recovery between tries. The session should follow a pyramid structure of increasing then decreasing difficulty.
""",
                    example: """
A climber begins with 2 problems at V3-V4 (6A-6B) level, then progresses to 2 problems at V5 (6C), 2 problems at their limit V6-V7 (7A), then works back down with 2 problems at V5 and 2 at V3-V4. Between each attempt, they rest 3-5 minutes for full recovery. The focus remains on perfect execution and maximum effort on each problem.
"""
                ),
                Exercise(
                    name: "Boulder Pyramids",
                    benefits: """
Develops power and strength endurance while maintaining quality through fatigue.
Best for: bouldery routes, power development, mental focus training
""",
                    equipment: """
Boulder wall with a range of problems at different grades. Problems should be spaced close enough to efficiently move between them.
""",
                    details: """
How to do it:
Select 8 different boulder problems ranging from moderate to maximum difficulty in a pyramid structure. Start with easier problems, progress to your hardest attempts, then finish with more moderate problems. The total volume challenges strength endurance while the peak difficulty develops maximum power.
""",
                    example: """
A climber who can send V7 (7A+) sets up a pyramid: 2 problems at V3 (6A), 2 problems at V5 (6C), 2 problems at V7 (7A+), then back down with 1 problem at V5 and 1 at V3. They rest 3-4 minutes between problems, focusing on quality movement even as fatigue builds. The session challenges both maximum strength (at the peak of the pyramid) and strength endurance (through accumulated volume).
"""
                ),
                Exercise(
                    name: "Boulder Intervals",
                    benefits: """
Builds power endurance and recovery ability between high-intensity efforts.
Best for: routes with multiple cruxes, competition climbing, power recovery
""",
                    equipment: """
Boulder wall with problems at approximately 70-80% of maximum difficulty. A timer for tracking rest periods.
""",
                    details: """
How to do it:
Select 5 boulder problems around 2-3 grades below your maximum. Climb each problem 3 times with exactly 3 minutes rest between attempts. Focus on maintaining perfect form and execution even as fatigue builds throughout the session.
""",
                    example: """
A climber who can send V6 (7A) selects 5 different V4 (6B+) boulder problems. They climb the first problem, then rest exactly 3 minutes before attempting it again. After the third completion of the first problem, they move to the second problem and repeat the pattern. By the final problem, significant pump and fatigue will have accumulated, challenging the climber to maintain technique and precision. The entire workout includes 15 boulder problems (5 problems × 3 attempts each) and takes approximately 45 minutes to complete.
"""
                ),
                Exercise(
                    name: "Volume Bouldering",
                    benefits: """
Develops climbing-specific work capacity and mental focus under increasing fatigue.
Best for: endurance improvement, climbing fitness, adaptation to high volume
""",
                    equipment: """
Boulder wall with numerous problems of moderate difficulty. A timer or clock to track the 45-minute window.
""",
                    details: """
How to do it:
Complete 15 boulder problems of moderate difficulty (60-70% of maximum) within a 45-minute time window. Pace yourself to maintain quality throughout, taking just enough rest between problems to recover partially but not completely. This exercise builds climbing-specific work capacity.
""",
                    example: """
A climber who can send V6 (7A) selects problems in the V3-V4 (6A-6B+) range. They give themselves 45 minutes to complete 15 different problems, which averages to 1 problem every 3 minutes. They can structure their rest as needed—either taking consistent short rests between each problem or occasionally taking longer rests after particularly challenging problems. The goal is to complete all 15 problems with good technique despite increasing fatigue.
"""
                ),
                Exercise(
                    name: "Weighted Pull-Ups",
                    benefits: """
Strengthens back and arms for powerful pulling on overhangs and roofs.
Best for: overhanging routes, roof climbs
""",
                    equipment: """
Pull-up bar, weight belt, or harness with weights attached. A dip belt or weighted vest can also be used for adding resistance.
""",
                    details: """
How to do it:
Attach a weight belt or hold a dumbbell between your feet. Perform pull-ups in sets of 3-8 reps, resting 2-3 minutes. Maintain good form—no kipping or swaying.
""",
                    example: """
A climber who can perform 10 bodyweight pull-ups should add enough weight (typically 10-20% of bodyweight to start) to reduce their max reps to 5-6. They perform 4 sets of 5 reps with 2-minute rest periods between sets. Form remains strict throughout, with full extension at the bottom and chin clearing the bar at the top of each repetition. As strength improves, weight is gradually increased to maintain the challenging nature of the exercise. For optimal transfer to climbing, some sets can be performed on different grip positions (wide grip, narrow grip) or with rings to better mimic the variable hand positions encountered while climbing.
"""
                ),
                Exercise(
                    name: "One-Arm Lock-Offs",
                    benefits: """
Builds unilateral pulling strength and control for steep terrain.
Best for: steep sport routes, roof problems
""",
                    equipment: """
Pull-up bar, jug holds on a systems wall, or rings. Resistance bands of varying strengths for assistance if needed.
""",
                    details: """
How to do it:
Use a pull-up bar or a ring. Pull up with both arms, then remove one arm and hold a lock-off for a few seconds. Lower slowly. Use assistance (band or slight toe support) if needed. Keep shoulder engaged.
""",
                    example: """
A climber begins by performing a two-arm pull-up to 90 degrees (arm bent at right angle). They then remove one arm, holding the lock-off position with the remaining arm for 5-7 seconds before lowering with control. For beginners, a resistance band looped around the wrist or foot can provide assistance. Advanced climbers might add a weighted vest or perform multiple lock-off positions (120°, 90°, 45°) during the descent. A typical workout includes 3-4 sets of 3 lock-offs per arm with 2-minute rest between each arm. Progress is measured by reducing assistance, increasing hold time, or adding weight.
"""
                ),
            ]
        ),
        
        // MARK: - Power
        
        ExerciseCategory(
            name: "Power",
            icon: "bolt.fill",
            description: """
Power is about producing force explosively this is particularly useful for dynamic movements, deadpoints and big moves on steep boulders or routes.
""",
            exercises: [
                Exercise(
                    name: "Campus Board Exercises",
                    benefits: """
Explosive pulling power for dynamic boulders or short cruxes.
Best for: dynamic boulders, short powerful routes, bouldery routes
""",
                    equipment: """
Campus board with various rung sizes. Traditional campus boards have 1-8 numbered rungs with 22cm spacing. Medium rungs (18-20mm) are standard, but beginners should start with larger rungs (24-30mm).
""",
                    details: """
How to do it:
On a campus board, focus on big moves and deadpoints between rungs. Keep sessions brief (under 20 minutes) to avoid overuse injuries. Explode through each move, using momentum, but maintain safe landing/spotting.
""",
                    example: """
A climber who can comfortably climb V5 (6C) starts with basic laddering: beginning with both hands on rung 1, they move right hand to rung 2, left hand to rung 3, right hand to rung 4, and so on. Once comfortable, they progress to skipping rungs (1-3-5) and then to more advanced exercises like "bumps" (moving one hand up and down without matching). Advanced climbers might practice double dynos (jumping both hands from rung 1 to rung 3 simultaneously). A typical session includes 3-4 different exercises with 2-3 attempts at each, taking full rest (2-3 minutes) between attempts. The entire campus board workout is limited to 15-20 minutes to prevent injury, and is performed only 1-2 times per week with at least 48 hours of recovery between sessions.
"""
                ),
                Exercise(
                    name: "Campus Bouldering",
                    benefits: """
Develops explosive power and contact strength for dynamic movements.
Best for: steep routes with dynamic moves, competition-style problems
""",
                    equipment: """
Boulder wall with problems requiring dynamic movement. The problems should have positive holds that can be "campused" (climbed without feet).
""",
                    details: """
How to do it:
Select 3 boulder problems that you can normally climb with feet. Campus these problems (climb without using feet) 3 times each, with 2.5 minutes rest between attempts. Choose problems that are several grades below your maximum to make campusing possible.
""",
                    example: """
A climber who sends V7 (7A+) selects three V3-V4 (6A-6B+) problems with positive holds and straightforward movements. They campus the first problem (using only their hands and keeping their feet off the wall), then rest for exactly 2.5 minutes. They repeat this problem two more times with the same rest interval, then move to the second problem and follow the same pattern. This exercise requires 9 total campusing efforts and develops explosive upper body power that transfers directly to steep climbing.
"""
                ),
                Exercise(
                    name: "Explosive Pull-Ups",
                    benefits: """
Enhances upper-body power and the ability to execute dynos or big moves.
Best for: dynamic boulders, comp-style problems
""",
                    equipment: """
Pull-up bar, jug holds on a systems wall, or large climbing holds mounted on a training board. The bar should be stable and secure.
""",
                    details: """
How to do it:
From a dead hang, pull up explosively so that your hands briefly lose contact with the bar at the top. Control the descent. Keep reps low (3-5) and rest fully between sets to maximize power output.
""",
                    example: """
A climber starts from a full dead hang position with arms completely straight. They initiate an explosive pull-up by driving their elbows down forcefully, accelerating throughout the movement so that at the top of the pull-up, their hands momentarily lose contact with the bar (even just 1-2cm of separation). They then catch the bar and control the descent. A typical session includes 4-5 sets of 3-5 repetitions with full recovery (2-3 minutes) between sets. Form is crucial - the explosive drive should come from the lats and arms, not from kicking or swinging the legs. As they progress, climbers can aim for higher hand clearance or clapping between release and re-grip. This exercise should be performed fresh, typically at the beginning of a power-focused training session.
"""
                )
            ]
        ),
        
        // MARK: - Core
        
        ExerciseCategory(
            name: "Core",
            icon: "figure.core.training",
            description: """
Core strength is essential for maintaining body tension, specifically on overhangs, when performing technical moves and preventing injury.

Developing a strong and stable core allows for more efficient movement and better power transfer between upper and lower body.
""",
            exercises: [
                Exercise(
                    name: "Front Lever Progressions",
                    benefits: """
Develops core and shoulder strength for horizontal or roof climbing.
Best for: overhangs, roof problems
""",
                    equipment: """
Pull-up bar, rings, or sturdy horizontal bar. Rings are preferred for reduced wrist strain and better shoulder positioning.
""",
                    details: """
How to do it:
Work through progressions: tuck lever → advanced tuck → one-leg front lever → full front lever. Practice holding each position for 5-10 seconds. Rest fully between attempts and maintain safe shoulder engagement.
""",
                    example: """
A beginner starts with the tuck lever position, pulling from a dead hang to bring the knees tightly to the chest while keeping the body horizontal. They hold this position for 5-8 seconds, then lower with control. After 3-4 months of consistent practice, they progress to an advanced tuck with legs extended slightly. Intermediate climbers work on the one-leg front lever (one leg extended, one tucked), while advanced climbers aim for the full front lever with both legs extended. A typical session includes 5-6 sets of 5-8 second holds with 2-minute rest periods. Proper form is critical - the back should remain flat, shoulders engaged, and arms straight throughout the hold.
"""
                ),
                Exercise(
                    name: "Hanging Knee Raises",
                    benefits: """
Strengthens lower abdominals for improved body tension and leg control.
Best for: all climbing styles, particularly overhanging routes
""",
                    equipment: """
Pull-up bar, fingerboard, or sturdy overhead holds that allow for hanging.
""",
                    details: """
How to do it:
Hang from a bar with straight arms. Keeping knees bent at 90 degrees, raise them toward your chest until your thighs are parallel to the ground. Lower with control and repeat. Complete 3 sets of 10-15 repetitions with 60-90 seconds rest between sets.
""",
                    example: """
A climber hangs from a pull-up bar with arms fully extended and shoulders engaged. They bend their knees to 90 degrees, then raise them toward their chest until their thighs are parallel to the floor. After a brief hold at the top position, they lower their legs with control. They complete 3 sets of 12 repetitions with 60 seconds rest between sets. Throughout the exercise, they focus on using core strength rather than momentum, maintaining engaged shoulders and minimizing swinging.
"""
                ),
                Exercise(
                    name: "Window Wipers",
                    benefits: """
Develops rotational core strength and obliques for body positioning and twisting movements.
Best for: overhanging routes, dynamic movement, maintaining body tension during complex moves
""",
                    equipment: """
Pull-up bar, fingerboard, or sturdy overhead holds that allow for hanging.
""",
                    details: """
How to do it:
Hang from a bar, raise your legs to a 90-degree angle, then rotate them side to side like windshield wipers. Keep your upper body stable throughout the movement. Complete 3 sets of 8-10 full rotations (each side counts as one) with 90 seconds rest between sets.
""",
                    example: """
A climber hangs from a pull-up bar with arms extended and shoulders engaged. They raise their legs to a 90-degree position (parallel to the floor), then rotate both legs together to the right as far as possible while maintaining control. After reaching the right side, they reverse the movement and rotate to the left side. They complete 3 sets of 8 full rotations with 90 seconds rest between sets. For beginners, the exercise can be performed with bent knees, while advanced climbers can extend the legs fully for maximum difficulty.
"""
                ),
                Exercise(
                    name: "Plank",
                    benefits: """
Builds basic core stability and isometric strength for maintaining body tension.
Best for: all climbing styles, foundational stability training
""",
                    equipment: """
Exercise mat or padded floor. No specialized equipment required.
""",
                    details: """
How to do it:
Assume a push-up position but with weight on forearms instead of hands. Keep body in a straight line from head to heels, engage your core, and hold. Complete 3 sets, holding each plank for 30-60 seconds with 60 seconds rest between sets.
""",
                    example: """
A climber positions their forearms on the floor with elbows directly beneath the shoulders, extending their legs behind them with toes tucked under. They engage their core to maintain a straight line from head to heels, avoiding letting the hips sag or pike up. They hold this position for 45 seconds, focusing on breathing steadily and maintaining proper form. After 60 seconds rest, they repeat for 2 more sets. For variation and progression, they might alternate with side planks (30 seconds each side) or add small movements like hip dips.
"""
                ),
                Exercise(
                    name: "Hanging Leg Raises",
                    benefits: """
Targets deep core muscles and hip flexors for high foot placements and maintaining tension.
Best for: steep routes, dynamic movement, precision footwork
""",
                    equipment: """
Pull-up bar, fingerboard, or sturdy overhead holds that allow for hanging.
""",
                    details: """
How to do it:
Hang from a bar with straight arms. Keeping your legs straight, raise them toward the bar until they form at least a 90-degree angle with your torso. Lower with control and repeat. Complete 3 sets of 8-12 repetitions with 90 seconds rest between sets.
""",
                    example: """
A climber hangs from a pull-up bar with arms fully extended and shoulders engaged. Starting with legs hanging straight down, they raise both legs simultaneously while keeping them straight, until they reach or exceed a position parallel to the ground. After a brief hold at the top position, they lower their legs with control. They complete 3 sets of 10 repetitions with 90 seconds rest between sets. Beginners can start with bent knees, while advanced climbers can progress to raising the legs all the way to touch the bar (toes-to-bar variation).
"""
                )
            ]
        ),
        
        // MARK: - Mobility and Warm Pps
        
        ExerciseCategory(
                    name: "Mobility",
                    icon: "figure.pilates",
                    description: """
        Mobility is crucial for accessing difficult positions, utilising high footholds and is vital for preventing injury.
        
        Improved flexibility allows for more efficient movement patterns and expanded reach on the wall.
        """,
                    exercises: [
                        Exercise(
                            name: "Flexibility and Mobility Circuit",
                            benefits: """
        Improves range of motion for high steps, wide stems, and awkward body positions.
        Best for: technical climbing, slab routes, competition climbing
        Priority: High
        """,
                            equipment: """
        Yoga mat, resistance bands, or foam blocks for support. A clear space for movement and stretching exercises.
        """,
                            details: """
        Perform a series of climbing-specific mobility exercises targeting hips, shoulders, and ankles. Include dynamic movements and static holds, focusing on ranges of motion commonly used in climbing. Hold stretches for 30-60 seconds.
        """,
                            example: """
        A climber performs a 15-minute mobility circuit 3 times per week, including: 1) Deep squat holds (60 seconds) for ankle mobility, 2) Frog stretch (60 seconds) for hip internal rotation, 3) Lizard pose (45 seconds each side) for hip flexors, 4) Thread the needle (30 seconds each side) for thoracic rotation, 5) Wall slides (10 repetitions) for shoulder mobility, and 6) Wrist extensor and flexor stretches (30 seconds each). The circuit concludes with movement-specific exercises like controlled high steps against a wall and gentle twisting motions mimicking climbing positions. Consistent practice improves the climber's ability to use high foot placements, execute stemming moves in corners, and maintain body tension in awkward positions.
        """
                        ),
                        Exercise(
                            name: "Dynamic Hip Mobility",
                            benefits: """
        Enhances hip range of motion for high steps, drop knees, and technical footwork.
        Best for: technical face climbing, slab routes, competition climbing
        """,
                            equipment: """
        Yoga mat or padded floor. A stable wall or support for balance during standing exercises.
        """,
                            details: """
        Perform dynamic hip mobility exercises that mimic climbing movements. Include leg swings, hip circles, and controlled reaching motions. Focus on smooth movement through a full range of motion without bouncing or forcing.
        """,
                            example: """
        A climber begins with a 5-minute general warmup to raise body temperature, then performs a series of dynamic hip mobility exercises: 1) Standing leg swings (front-to-back and side-to-side, 15 repetitions each leg), 2) Hip circles in quadruped position (10 in each direction per leg), 3) World's greatest stretch (5 repetitions per side, holding the deepest position for 2 seconds), 4) Fire hydrants with hip openers (12 per side), and 5) Dynamic high step practice against a wall (10 per leg). The entire sequence takes 10-12 minutes and should be performed before climbing sessions, especially when routes require high steps or flexible hip positions. This routine progressively opens the hip joint in multiple planes of motion, preparing the body for the varied positions encountered during climbing. Regular practice not only improves performance but also reduces injury risk by developing controlled mobility.
        """
                        ),
                        Exercise(
                            name: "Shoulder Mobility Flow",
                            benefits: """
        Develops shoulder flexibility and stability for reaches, lockoffs, and overhead movements.
        Best for: steep climbing, mantling, compression problems
        """,
                            equipment: """
        Light resistance band (optional). A clear space for arm movements.
        """,
                            details: """
        Perform a sequence of shoulder mobility exercises that take the joint through its full range of motion. Include arm circles, wall slides, and band pull-aparts. Focus on control and proper scapular positioning throughout.
        """,
                            example: """
        A climber performs a progressive shoulder mobility routine consisting of: 1) Arm circles (10 forward, 10 backward) of increasing size, 2) Shoulder rolls (10 forward, 10 backward), 3) Wall slides (10 repetitions, focusing on keeping arms in contact with the wall while sliding from waist to overhead position), 4) Band pull-aparts (15 repetitions at shoulder height, 15 at overhead position), and 5) Shoulder dislocates using a resistance band or PVC pipe (8-10 repetitions with controlled movement). The sequence concludes with scapular pushups (10-12 repetitions) to activate the stabilizing muscles around the shoulder blades. This comprehensive routine addresses both mobility and stability, preparing the shoulders for the demands of reaching overhead, maintaining lockoff positions, and performing compression moves. The entire flow takes approximately 8-10 minutes and can be performed 3-4 times weekly, either before climbing or as part of a dedicated mobility session.
        """
                        ),
                        Exercise(
                            name: "Ankle and Foot Mobility",
                            benefits: """
        Improves foot control and ankle flexibility for precise edging and smearing.
        Best for: technical slab climbing, face climbing, small footholds
        """,
                            equipment: """
        Balance board, small ball, or towel for foot exercises. A step or raised platform for calf stretches.
        """,
                            details: """
        Perform exercises that increase ankle range of motion and foot strength. Include calf stretches, ankle circles, towel scrunches, and balance exercises. Focus on controlled, deliberate movement.
        """,
                            example: """
        A climber's foot and ankle mobility routine includes: 1) Ankle circles (15 in each direction per foot), 2) Calf stretches on a step (straight knee and bent knee variations, 30 seconds each position per leg), 3) Towel scrunches with toes (3 sets of 20 scrunches per foot), 4) Toe yoga (isolating and lifting individual toes, 10 repetitions per toe), and 5) Single-leg balance on a balance board or uneven surface (30 seconds per leg, 3 sets). For advanced practice, they add controlled transitions between different foot positions used in climbing - edging, smearing, and toeing-in - while balanced on one leg. This routine simultaneously develops mobility, proprioception, and strength in the feet and ankles, directly transferring to more precise and confident footwork on small holds. The exercises can be performed 3-4 times weekly, either as a standalone routine or integrated into a warm-up before technical climbing sessions.
        """
                        )
                    ]
                ),
        
        // MARK: - Warm Up and Cool Down
        ExerciseCategory(
            name: "Warm Up and Cool Down",
            icon: "figure.jumprope.circle",
            description: """
                Warming up for training is crucial for injury prevention and learning new movement.
                This routine prepares your body for the demands of climbing through progressive activation.
                
                Cool down routines facilitate recovery by gradually reducing intensity and promoting blood flow for waste removal.
                Incorporate these at the end of sessions to aid muscle recovery and maintain flexibility.
                """,
            exercises: [
                Exercise(
                    name: "General Warm-up",
                    benefits: """
        Prepares the body for climbing by increasing blood flow, raising muscle temperature, and improving joint mobility.
        Best for: all climbing sessions
        """,
                    equipment: """
        Any climbing wall or open space for movement.
        """,
                    details: """
        1. 5 min light cardio (jogging, jumping jacks, easy traversing)
        2. Dynamic stretching (shoulders, hips, fingers)
        3. Progressive climbing from very easy grades
        4. Gradually increase difficulty over 10–15 min
        5. Include all grip types you'll use in session
        """,
                    example: """
        Start with 5 min easy traversing 3–4 grades below max, 5 min of arm circles/leg swings/hip circles/finger flexing, then 5–10 easy problems up to ~80% session intensity.
        """
                ),
                Exercise(
                    name: "Dynamic Stretching",
                    benefits: """
        Increases range of motion and prepares muscles for dynamic movement through active stretching.
        Best for: warm-up routines, injury prevention
        """,
                    equipment: """
        Open floor space or wall for support.
        """,
                    details: """
        Arm circles, leg swings front-to-back & side-to-side, hip circles, torso twists, shoulder rolls, cross-body arm swings, wrist circles, finger flexion/extension, walking lunges with rotation, high knees, and butt kicks. Perform smoothly without bouncing.
        """,
                    example: """
        10 arm circles each way, 10 leg swings each direction, 10 hip circles, 10 torso twists each side, shoulder rolls, wrist circles, then 10 walking lunges with rotation and 30 s of high knees/butt kicks.
        """
                    ),
                Exercise(
                    name: "Light Stretching",
                    benefits: """
        Promotes recovery and maintains flexibility through gentle static stretching.
        Best for: cool-down routines, recovery days
        """,
                    equipment: """
        Yoga mat or comfortable floor space.
        """,
                    details: """
        Cool-down stretching routine:
        1. Forearm stretches (prayer position and reverse, 30 seconds each)
        2. Shoulder stretches (cross-body and overhead tricep, 30 seconds each side)
        3. Hip flexor lunges (30 seconds each side)
        4. Hamstring stretches (standing or seated, 30 seconds each side)
        5. Calf stretches against wall (30 seconds each)
        6. Gentle spinal twists (seated or lying, 30 seconds each side)
        7. Child's pose or similar relaxation position (1 minute)

        Hold each stretch at a point of mild tension, never to the point of pain. Breathe deeply throughout.
        """,
                    example: """
        After climbing, start with forearm stretches by placing palms together in prayer position and lowering hands while keeping palms together. Hold for 30 seconds, then flip hands so fingers point down for reverse prayer stretch. Continue through all stretches, focusing on deep breathing and gradual relaxation. The full routine takes 10-15 minutes.
        """
                ),
                Exercise(
                    name: "Cool-down Exercises",
                    benefits: """
        Facilitates recovery by gradually reducing intensity and promoting blood flow to aid in waste removal.
        Best for: end of climbing sessions
        """,
                    equipment: """
        Climbing wall for easy traversing, floor space for stretching.
        """,
                    details: """
        1. 5–10 min easy traversing or very low-intensity climbing
        2. 5 min walking or light movement
        3. Static stretching of worked muscles
        4. Antagonist work (10–15 push-ups or band chest flies)
        5. Deep breathing (2–3 min)
        """,
                    example: """
        Traverse for 5–10 min, walk/light arm swings for 5 min, stretch for 10–15 min, finish with push-ups and 2 min of diaphragmatic breathing.
        """
                )
            ]
        ),

        // MARK: - Technique
        ExerciseCategory(
            name: "Technique",
            icon: "figure.walk",
            description: """
Technique focuses on efficient movement, footwork, and body positioning. 
Often overlooked, good technique can significantly boost your climbing ability—even if your strength or endurance lags.
""",
            exercises: [
                Exercise(
                    name: "Silent Feet Drills",
                    benefits: """
Teaches precise foot placements and overall body control.
Best for: technical slabs, vertical routes
""",
                    equipment: """
Any climbing wall with a variety of footholds. This exercise is particularly effective on vertical to slightly overhanging walls with small or technical footholds.
""",
                    details: """
How to do it:
Climb a moderate route or problem, striving to place feet silently on each hold. Move slowly and focus on foot accuracy. Reducing noise typically means better footwork and less wasted energy.
""",
                    example: """
A climber selects a route 2-3 grades below their maximum ability (e.g., a 7a climber would choose a 6a/6a+ route). They climb the route at a deliberate pace, focusing intensely on each foot placement. Before placing a foot, they visually identify the optimal spot on the hold, then place their foot with precision directly on that spot without any readjustment or scraping. If they hear their foot make contact with the wall or need to readjust, they consider it a failed placement. The goal is to complete the entire route with completely silent, precise foot placements. This exercise can be made more challenging by using smaller footholds or climbing with eyes closed once the hand is securely on its hold until the foot is placed (vision-restricted footwork).
"""
                ),
                Exercise(
                    name: "Flagging Practice",
                    benefits: """
Improves body positioning and balance on the wall.
Best for: overhangs, vertical routes, technical faces, beginners
""",
                    equipment: """
Any climbing wall, but vertical to slightly overhanging walls with varied hold placements work best for practicing different flagging techniques.
""",
                    details: """
How to do it:
On a slightly overhanging or vertical route, deliberately use flagging (placing one foot behind or across the other) to maintain balance. Practice inside flags, outside flags, and back flags to reduce barn-door swings.
""",
                    example: """
A climber selects a route with moves that naturally induce rotation or barn-door tendencies (where the body wants to swing outward). For each move, they identify which type of flag would best counter the rotational force: an inside flag (foot on same side as gripping hand crosses behind), outside flag (foot on opposite side crosses in front), or rear flag (foot on same side extends behind for counterbalance). The climber deliberately practices all three flag types, spending 20-30 minutes on routes several grades below their limit. To increase challenge, they can select routes with holds that force cross-through moves or sidepulls, which naturally require flagging for balance. Advanced practice involves "eliminates" where certain footholds are intentionally skipped to force flagging where it might not otherwise be needed.
"""
                ),
                Exercise(
                    name: "High-Step Drills",
                    benefits: """
Develops hip mobility and the ability to pull up on high footholds.
Best for: slabs, technical face climbing
""",
                    equipment: """
Climbing wall with varied hold sizes and spacing. Vertical or slightly overhanging walls work best for this exercise, as they allow for controlled practice of high steps.
""",
                    details: """
How to do it:
Climb a wall of moderate difficulty but force yourself to place your foot on a higher hold than usual. This challenges flexibility and encourages a closer center of gravity to the wall.
""",
                    example: """
A climber selects a route 2-3 grades below their onsight level on a vertical wall. Instead of using the most obvious or convenient footholds, they deliberately seek out higher options that require lifting the foot to waist level or above. For each high step, they focus on proper technique: turning the hip outward (external rotation), keeping the body close to the wall, and using core tension to generate upward movement. The exercise progresses by selecting increasingly higher footholds that challenge the limits of mobility. A good benchmark is attempting to place the foot at or above the level of the opposite hand, requiring significant hip flexibility and core strength. This drill can be practiced for 15-20 minutes as part of a technical training session, targeting 8-10 deliberate high steps.
"""
                ),
                Exercise(
                    name: "Cross-Through Drills",
                    benefits: """
Enhances fluid movement and coordination in complex sequences.
Best for: complex sequences, boulders, sport routes
""",
                    equipment: """
Any climbing wall, but a systems wall or route with closely spaced holds in horizontal arrangements works best for practicing cross-throughs.
""",
                    details: """
How to do it:
On a route with closely spaced holds, practice crossing one arm over the other to reach the next hold. Focus on fluid transitions and maintaining balance through your core. This is crucial for intricate or reachy beta.
""",
                    example: """
A climber sets up or finds a traverse with multiple holds at the same height. Starting with both hands on holds, they reach across their body with one arm crossing over or under the other to grasp the next hold in sequence, without releasing the original hold. After securing the cross-through position, they bring their other hand past to continue the sequence. The climber focuses on maintaining body tension throughout the movement, using hip rotation and weight shifts to facilitate reaching. Advanced practice involves "elbow drops" (crossing under) and exploring different body positions during the cross. For a structured drill, the climber might perform 3-4 traverses of 10-15 moves each, deliberately incorporating at least 5-6 cross-throughs per traverse. This develops the coordination and body awareness needed for efficient movement on routes with complicated sequences.
"""
                ),
                Exercise(
                    name: "Open-Hand Grip Practice",
                    benefits: """
Helps reduce finger strain and develops grip endurance for slopers.
Best for: grip-intensive routes, sloper-heavy problems
""",
                    equipment: """
Any climbing wall with a variety of hold types. Particularly useful are walls with slopers, rounded edges, and larger holds that allow for grip variation.
""",
                    details: """
How to do it:
Climb routes or boulders using an open-hand grip (fingers slightly bent, not crimped). This technique spreads load across more finger joints and can prevent certain injuries. Gradually incorporate it to avoid overstrain.
""",
                    example: """
A climber selects routes several grades below their maximum level and commits to climbing them exclusively with open-hand grips (no full crimping allowed). On each hold, they focus on keeping their fingers relaxed and slightly curved rather than sharply bent at the joints. Initially, this might feel insecure, especially on smaller edges, but with practice becomes more comfortable and efficient. The climber might start with 15-20 minutes of focused practice on easier terrain before incorporating the technique into more challenging climbs. A good progression is to first master open-hand technique on jugs and positive edges, then gradually apply it to smaller holds and finally to micro-edges where possible. Regular practice of open-hand gripping not only reduces injury risk but develops forearm strength in a range of motion that transfers well to sloper-intensive climbing.
"""
                ),
                Exercise(
                    name: "Slow Climbing",
                    benefits: """
Builds precision, control, and mental focus for onsight or flash attempts.
Best for: onsight attempts, flash attempts
""",
                    equipment: """
Any climbing wall with routes of appropriate difficulty. A timer or partner to help monitor pace can be helpful.
""",
                    details: """
How to do it:
Pick a route and climb each move deliberately in slow motion. Pause on each hold. This forces you to analyze body position, foot placement, and technique. It also trains patience and mental composure on the wall.
""",
                    example: """
A climber selects a route 2-3 grades below their onsight level and commits to climbing it at about 1/3 their normal pace. Before each hand movement, they pause for 3-5 seconds on the current holds, consciously analyzing their body position, breathing, and the upcoming sequence. They move to the next hold with deliberate control, then pause again. For foot placements, they take time to visually identify the optimal position on the foothold before placing their foot with precision. A typical slow climbing session might involve 2-3 routes climbed in this manner, taking 10-15 minutes per route that would normally require only 3-5 minutes. This practice develops several crucial skills for onsighting: efficient resting positions, movement planning while on the wall, and the mental discipline to climb methodically under fatigue. Advanced practitioners might incorporate breath control, climbing sections of the route with eyes closed, or deliberately planning multiple moves ahead during each pause.
"""
                ),
                Exercise(
                    name: "Rest Position Training",
                    benefits: """
Improves recovery efficiency during routes and endurance capacity.
Best for: endurance routes, competitions, redpoint attempts
""",
                    equipment: """
Lead wall or any climbing wall with varied terrain and holds. Routes with potential rest positions are ideal for practice.
""",
                    details: """
How to do it:
Identify and practice efficient rest positions such as knee bars, stems, and shake-out stances. Focus on maximizing recovery while minimizing energy expenditure. Practice finding the optimal body position and breathing pattern.
""",
                    example: """
A climber selects a route with several potential rest positions (jugs with good feet, stems in corners, knee bars, etc.). They climb to the first rest position and deliberately explore different body positions to find the most efficient stance - one that allows maximum weight on the feet and minimum strain on the arms. Once the optimal position is found, they practice relaxing one arm at a time, shaking out while maintaining body position through core engagement. The climber focuses on controlled breathing (deep belly breaths) and mental relaxation during the rest. They hold each optimized rest position for 30-60 seconds before moving to the next section. After practicing individual rest positions, they climb the entire route, incorporating strategic rests at predetermined points. This exercise teaches climbers to identify potential rest opportunities, maximize recovery efficiency, and develop the mental discipline to take rests when needed rather than rushing through routes.
"""
                ),
                Exercise(
                    name: "Dynamic Movement Practice",
                    benefits: """
Develops coordination and confidence for dynamic moves and deadpoints.
Best for: competition climbing, bouldery routes, overhanging terrain
""",
                    equipment: """
Boulder wall with holds set to require dynamic movements. Adequate crash pads for safety during practice.
""",
                    details: """
How to do it:
Practice controlled dynamic movements of increasing difficulty. Start with small "pop" moves and progress to larger dynos. Focus on accurate targeting, body positioning, and controlled landing on the destination hold.
""",
                    example: """
A climber sets up or finds a series of dynamic moves of increasing difficulty. They begin with small deadpoint movements (where one hand remains on the wall) between closely spaced holds, focusing on generating momentum through the legs and core rather than arms alone. Once comfortable with deadpoints, they progress to full dynos where both hands leave the wall simultaneously. For each movement, they practice the setup position, identifying the optimal body position that allows them to generate maximum momentum toward the target hold. The climber performs 6-8 attempts at each dynamic move, taking adequate rest between attempts to maintain quality. Throughout the practice, they focus on controlled takeoffs, accurate targeting, and solid catching technique - maintaining body tension throughout the movement and engaging the core upon contact with the target hold. This progressive approach builds both physical capability and the mental confidence needed for committing to dynamic movements during routes or boulders.
"""
                )
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1) Header on top (customizable)
                HeaderView()
                
                // 2) Main content: list of categories
                List {
                    ForEach(categories) { category in
                        NavigationLink(destination: ExerciseListView(category: category)) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.teal)
                                Text(category.name)
                            }
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            .navigationBarHidden(true)
            .onAppear {
                // If using a shared library manager
                ExerciseLibraryManager.shared.initializeWithLibrary(categories: categories)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Child Views

// MARK: - Exercise Category List View
struct ExerciseListView: View {
    let category: ExerciseCategory
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header with back button
            DetailHeaderView {
                dismiss()
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Category title
                    Text(category.name)
                        .font(.title)
                        .bold()
                        .foregroundColor(.deepPurple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Category description card
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.description)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Exercise list with cards
                    VStack(spacing: 10) {
                        ForEach(category.exercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                HStack {
                                    // Exercise icon based on type
                                    getExerciseIcon(for: exercise.name)
                                        .font(.title3)
                                        .foregroundColor(.ascendGreen)
                                        .frame(width: 40)
                                    
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(.systemGray3))
                                }
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all))
    }
    
    // Helper to get appropriate icon for an exercise
    private func getExerciseIcon(for exerciseName: String) -> some View {
        let name = exerciseName.lowercased()
        
        // Choose icon based on exercise name keywords
        let iconName: String
        if name.contains("campus") {
            iconName = "figure.climbing"
        } else if name.contains("hang") || name.contains("fingerboard") {
            iconName = "hand.point.up.left.fill"
        } else if name.contains("interval") || name.contains("4x4") {
            iconName = "timer"
        } else if name.contains("continuous") || name.contains("endurance") {
            iconName = "infinity.circle"
        } else if name.contains("boulder") {
            iconName = "mountain.2.fill"
        } else if name.contains("route") {
            iconName = "map"
        } else if name.contains("pull") {
            iconName = "arrow.up.circle"
        } else if name.contains("mobility") || name.contains("flexibility") {
            iconName = "figure.flexibility"
        } else if name.contains("dynamic") {
            iconName = "figure.jumprope"
        } else if name.contains("rest") {
            iconName = "figure.mind.and.body"
        } else if name.contains("foot") || name.contains("feet") || name.contains("ankle") {
            iconName = "shoe"
        } else if name.contains("core") || name.contains("plank") || name.contains("lever") {
            iconName = "figure.core.training"
        } else if name.contains("shoulder") {
            iconName = "figure.strengthtraining.functional"
        } else {
            iconName = "figure.climbing"
        }
        
        return Image(systemName: iconName)
    }
}

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header with back button
            DetailHeaderView {
                dismiss()
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise title
                    Text(exercise.name)
                        .font(.title)
                        .bold()
                        .foregroundColor(.deepPurple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Benefits card
                    CardView(title: "Benefits") {
                        Text(exercise.benefits)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Equipment Required
                    CardView(title: "Equipment") {
                        Text(exercise.equipment)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // How to perform card
                    CardView(title: "How to Perform") {
                        Text(exercise.details)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Example Session
                    CardView(title: "Example Session") {
                        Text(exercise.example)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Data Models
// These models need to be accessible outside the file, so make sure they're public

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let benefits: String
    let equipment: String
    let details: String
    let example: String
}

// Updated model now includes a 'description' for category overview
struct ExerciseCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let exercises: [Exercise]
}

// MARK: - Preview
struct ExerciseLib_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseLib()
    }
}
 
