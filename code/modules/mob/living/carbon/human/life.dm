//NOTE: Breathing happens once per FOUR TICKS, unless the last breath fails. In which case it happens once per ONE TICK! So oxyloss healing is done once per 4 ticks while oxyloss damage is applied once per tick!
#define HUMAN_MAX_OXYLOSS 3 //Defines how much oxyloss humans can get per tick. A tile with no air at all (such as space) applies this value, otherwise it's a percentage of it.

#define HEAT_DAMAGE_LEVEL_1 2 //Amount of damage applied when your body temperature just passes the 360.15k safety point
#define HEAT_DAMAGE_LEVEL_2 4 //Amount of damage applied when your body temperature passes the 400K point
#define HEAT_DAMAGE_LEVEL_3 8 //Amount of damage applied when your body temperature passes the 1000K point

#define COLD_DAMAGE_LEVEL_1 0.5 //Amount of damage applied when your body temperature just passes the 260.15k safety point
#define COLD_DAMAGE_LEVEL_2 1.5 //Amount of damage applied when your body temperature passes the 200K point
#define COLD_DAMAGE_LEVEL_3 3 //Amount of damage applied when your body temperature passes the 120K point

//Note that gas heat damage is only applied once every FOUR ticks.
#define HEAT_GAS_DAMAGE_LEVEL_1 2 //Amount of damage applied when the current breath's temperature just passes the 360.15k safety point
#define HEAT_GAS_DAMAGE_LEVEL_2 4 //Amount of damage applied when the current breath's temperature passes the 400K point
#define HEAT_GAS_DAMAGE_LEVEL_3 8 //Amount of damage applied when the current breath's temperature passes the 1000K point

#define COLD_GAS_DAMAGE_LEVEL_1 0.5 //Amount of damage applied when the current breath's temperature just passes the 260.15k safety point
#define COLD_GAS_DAMAGE_LEVEL_2 1.5 //Amount of damage applied when the current breath's temperature passes the 200K point
#define COLD_GAS_DAMAGE_LEVEL_3 3 //Amount of damage applied when the current breath's temperature passes the 120K point

/mob/living/carbon/human
	var/oxygen_alert = 0
	var/toxins_alert = 0
	var/fire_alert = 0
	var/pressure_alert = 0
	var/prev_gender = null // Debug for plural genders
	var/temperature_alert = 0


/mob/living/carbon/human/Life()
	set background = 1

	if (monkeyizing)	return
	if(!loc)			return	// Fixing a null error that occurs when the mob isn't found in the world -- TLE

	/*
	//This code is here to try to determine what causes the gender switch to plural error. Once the error is tracked down and fixed, this code should be deleted
	//Also delete var/prev_gender once this is removed.
	if(prev_gender != gender)
		prev_gender = gender
		if(gender in list(PLURAL, NEUTER))
			message_admins("[src] ([ckey]) gender has been changed to plural or neuter. Please record what has happened recently to the person and then notify coders. (<A HREF='?_src_=holder;adminmoreinfo=\ref[src]'>?</A>)  (<A HREF='?_src_=vars;Vars=\ref[src]'>VV</A>) (<A HREF='?priv_msg=\ref[src]'>PM</A>) (<A HREF='?_src_=holder;adminplayerobservejump=\ref[src]'>JMP</A>)")
	*/
	//Apparently, the person who wrote this code designed it so that
	//blinded get reset each cycle and then get activated later in the
	//code. Very ugly. I dont care. Moving this stuff here so its easy
	//to find it.
	blinded = null
	fire_alert = 0 //Reset this here, because both breathe() and handle_environment() have a chance to set it.

	//TODO: seperate this out
	var/datum/gas_mixture/environment = loc.return_air()

	//No need to update all of these procs if the guy is dead.
	if(stat != DEAD)
		if(air_master.current_cycle%4==2 || failed_last_breath) 	//First, resolve location and get a breath
			breathe() 				//Only try to take a breath every 4 ticks, unless suffocating

		//Updates the number of stored chemicals for powers
		handle_changeling()

		//Mutations and radiation
		handle_mutations_and_radiation()

		//Chemicals in the body
		handle_chemicals_in_body()

		//Disabilities
		handle_disabilities()

		//Random events (vomiting etc)
		handle_random_events()

	//Handle temperature/pressure differences between body and environment
	handle_environment(environment)

	//stuff in the stomach
	handle_stomach()

	//Status updates, death etc.
	handle_regular_status_updates()		//TODO: optimise ~Carn
	update_canmove()

	//Update our name based on whether our face is obscured/disfigured
	name = get_visible_name()

	handle_regular_hud_updates()

	// Grabbing
	for(var/obj/item/weapon/grab/G in src)
		G.process()


/mob/living/carbon/human

	proc/handle_disabilities()
		if (disabilities & EPILEPSY)
			if ((prob(1) && paralysis < 1))
				src << "\red You have a seizure!"
				for(var/mob/O in viewers(src, null))
					if(O == src)
						continue
					O.show_message(text("\red <B>[src] starts having a seizure!"), 1)
				deal_damage(10, PARALYZE)
				make_jittery(1000)
		if (disabilities & COUGHING)
			if ((prob(5) && paralysis <= 1))
				drop_item()
				spawn( 0 )
					emote("cough")
					return
		if (disabilities & TOURETTES)
			if ((prob(10) && paralysis <= 1))
				spawn(0)
					switch(rand(1, 3))
						if(1)
							emote("twitch")
						if(2 to 3)
							say("[prob(50) ? ";" : ""][pick("SHIT", "PISS", "FUCK", "CUNT", "COCKSUCKER", "MOTHERFUCKER", "TITS")]")
					var/old_x = pixel_x
					var/old_y = pixel_y
					pixel_x += rand(-2,2)
					pixel_y += rand(-1,1)
					sleep(2)
					pixel_x = old_x
					pixel_y = old_y
					return
		if (disabilities & NERVOUS)
			if (prob(10))
				stuttering = max(10, stuttering)
		if (brain_damage >= 60 && stat != 2)
			if (prob(3))
				switch(pick(1,2,3))
					if(1)
						say(pick("IM A PONY NEEEEEEIIIIIIIIIGH", "without oxigen blob don't evoluate?", "CAPTAINS A COMDOM", "[pick("", "that faggot traitor")] [pick("joerge", "george", "gorge", "gdoruge")] [pick("mellens", "melons", "mwrlins")] is grifing me HAL;P!!!", "can u give me [pick("telikesis","halk","eppilapse")]?", "THe saiyans screwed", "Bi is THE BEST OF BOTH WORLDS>", "I WANNA PET TEH monkeyS", "stop grifing me!!!!", "SOTP IT#"))
					if(2)
						say(pick("FUS RO DAH","fucking 4rries!", "stat me", ">my face", "roll it easy!", "waaaaaagh!!!", "red wonz go fasta", "FOR TEH EMPRAH", "lol2cat", "dem dwarfs man, dem dwarfs", "SPESS MAHREENS", "hwee did eet fhor khayosss", "lifelike texture ;_;", "luv can bloooom", "PACKETS!!!"))
					if(3)
						emote("drool")


	proc/handle_mutations_and_radiation()
		if((HULK in mutations) && health < 25)
			mutations.Remove(HULK)
			update_mutations()		//update our mutation overlays
			src << "\red You suddenly feel very weak."
			deal_damage(3, WEAKEN)
			emote("collapse")

		if(radiation)
			if(radiation > 100)
				radiation = 100
				deal_damage(10, WEAKEN)
				src << "\red You feel weak."
				emote("collapse")

			switch(radiation)
				if(-INFINITY to -1)
					radiation = 0
				if(1 to 49)
					radiation--
					if(prob(25))
						deal_damage(1, TOX)

				if(50 to 74)
					radiation -= 2
					deal_damage(1, TOX)
					if(prob(5))
						radiation -= 5
						deal_damage(3, WEAKEN)
						src << "\red You feel weak."
						emote("collapse")

				if(75 to 100)
					radiation -= 3
					deal_damage(3, TOX)
					if(prob(1))
						src << "\red You mutate!"
						randmutb(src)
						domutcheck(src,null)
						emote("gasp")
		return


	get_breath_from_internal(volume_needed)
		if(!internal)
			return null
		if(!contents.Find(internal))
			internal = null
		if(!wear_mask || !(wear_mask.flags & MASKINTERNALS))
			internal = null

		if(internal)
			return internal.remove_air_volume(volume_needed)
		else if(internals)
			internals.icon_state = "internal0"
		return null


	handle_breath(datum/gas_mixture/breath)
		if((status_flags & GODMODE))
			return

		if(!breath || (breath.total_moles() == 0) || suiciding)
			if(suiciding)
				deal_damage(10, OXY)//You die very fast when suiciding
				failed_last_breath = 1
				oxygen_alert = max(oxygen_alert, 1)
				return 0
			if(reagents.has_reagent("inaprovaline"))//This chem means you dont need to breath, however suicide ignores it because suicide
				return
			deal_damage(HUMAN_MAX_OXYLOSS, OXY)
			failed_last_breath = 1
			oxygen_alert = max(oxygen_alert, 1)
			return 0

		if(dna && dna.mutantrace == "adamantine")
			return 1

		var/safe_oxygen_min = 16 // Minimum safe partial pressure of O2, in kPa
		//var/safe_oxygen_max = 140 // Maximum safe partial pressure of O2, in kPa (Not used for now)
		var/safe_co2_max = 10 // Yes it's an arbitrary value who cares?
		var/safe_toxins_max = 0.005
		var/SA_para_min = 1
		var/SA_sleep_min = 5
		var/oxygen_used = 0
		var/breath_pressure = (breath.total_moles()*R_IDEAL_GAS_EQUATION*breath.temperature)/BREATH_VOLUME

		//Partial pressure of the O2 in our breath
		var/O2_pp = (breath.oxygen/breath.total_moles())*breath_pressure
		// Same, but for the toxins
		var/Toxins_pp = (breath.toxins/breath.total_moles())*breath_pressure
		// And CO2, lets say a PP of more than 10 will be bad (It's a little less really, but eh, being passed out all round aint no fun)
		var/CO2_pp = (breath.carbon_dioxide/breath.total_moles())*breath_pressure

		//Oyxgen processing
		if(O2_pp >= safe_oxygen_min)	//Enough o2
			failed_last_breath = 0
			deal_damage(-5, OXY)
			oxygen_used = breath.oxygen/6
			oxygen_alert = 0
		else							//Need more o2
			if(prob(20))
				spawn(0) emote("gasp")
			if(O2_pp > 0)
				var/ratio = safe_oxygen_min/O2_pp
				deal_damage(min(5*ratio, HUMAN_MAX_OXYLOSS), OXY)// Don't fuck them up too fast (space only does HUMAN_MAX_OXYLOSS after all!)
				failed_last_breath = 1
				oxygen_used = breath.oxygen*ratio/6
			else
				deal_damage(HUMAN_MAX_OXYLOSS, OXY)
				failed_last_breath = 1
			oxygen_alert = max(oxygen_alert, 1)

		breath.oxygen -= oxygen_used
		breath.carbon_dioxide += oxygen_used
		//End Oxygen processing

		//Hot/Cold Gas breathing
		if((abs(310.15 - breath.temperature) > 50) && !(TEMPATURE_RESIST in mutations)) // Hot air hurts :(
			if(breath.temperature < 260.15)
				if(prob(20))
					src << "\red You feel your face freezing and an icicle forming in your lungs!"
			else if(breath.temperature > 360.15)
				if(prob(20))
					src << "\red You feel your face burning and a searing heat in your lungs!"

			switch(breath.temperature)
				if(-INFINITY to 120)
					deal_damage(COLD_GAS_DAMAGE_LEVEL_3, BURN, null ,"head")
					fire_alert = max(fire_alert, 1)
				if(120 to 200)
					deal_damage(COLD_GAS_DAMAGE_LEVEL_2, BURN, null ,"head")
					fire_alert = max(fire_alert, 1)
				if(200 to 260)
					deal_damage(COLD_GAS_DAMAGE_LEVEL_1, BURN, null ,"head")
					fire_alert = max(fire_alert, 1)
				if(360 to 400)
					deal_damage(HEAT_GAS_DAMAGE_LEVEL_1, BURN, null ,"head")
					fire_alert = max(fire_alert, 2)
				if(400 to 1000)
					deal_damage(HEAT_GAS_DAMAGE_LEVEL_2, BURN, null ,"head")
					fire_alert = max(fire_alert, 2)
				if(1000 to INFINITY)
					deal_damage(HEAT_GAS_DAMAGE_LEVEL_3, BURN, null ,"head")
					fire_alert = max(fire_alert, 2)
		//End Hot/Cold Gas breathing

		//Gasmask goes here
		if(istype(wear_mask, /obj/item/clothing/mask/gas))//The gasmask prevents odd gasses from affecting you so we just end here
			return 1


		//CO2 does not affect failed_last_breath. So if there was enough oxygen in the air but too much co2, this will hurt you, but only once per 4 ticks, instead of once per tick.
		if(CO2_pp <= safe_co2_max)
			co2overloadtime = 0
		else
			if(!co2overloadtime) // If it's the first breath with too much CO2 in it, lets start a counter, then have them pass out after 12s or so.
				co2overloadtime = world.time
			else if(world.time - co2overloadtime > 120)
				deal_damage(3, PARALYZE)
				deal_damage(3, OXY)// Lets hurt em a little, let them know we mean business
				if(world.time - co2overloadtime > 300) // They've been in here 30s now, lets start to kill them for their own good!
					deal_damage(8, OXY)
			if(prob(20)) // Lets give them some chance to know somethings not right though I guess.
				spawn(0) emote("cough")
		//End Co2 processing

		//Plasma processing
		if(Toxins_pp <= safe_toxins_max)
			toxins_alert = 0
		else
			var/ratio = (breath.toxins/safe_toxins_max) * 10
			//adjustToxLoss(Clamp(ratio, MIN_PLASMA_DAMAGE, MAX_PLASMA_DAMAGE))	//Limit amount of damage toxin exposure can do per second
			if(reagents)
				reagents.add_reagent("plasma", Clamp(ratio, MIN_PLASMA_DAMAGE, MAX_PLASMA_DAMAGE))
			toxins_alert = max(toxins_alert, 1)
		//End Plasma processing

		//N2O, AgentB processing
		if(breath.trace_gases.len)	// If there's some other shit in the air lets deal with it here.
			for(var/datum/gas/sleeping_agent/SA in breath.trace_gases)
				var/SA_pp = (SA.moles/breath.total_moles())*breath_pressure
				if(SA_pp > SA_para_min) // Enough to make us paralysed for a bit
					deal_damage(3, PARALYZE)// 3 gives them one second to wake up and run away a bit!
					if(SA_pp > SA_sleep_min)// Enough to make us sleep as well
						sleeping = max(sleeping+2, 10)
				else if(SA_pp > 0.01)	// There is sleeping gas in their lungs, but only a little, so give them a bit of a warning
					if(prob(20))
						spawn(0) emote(pick("giggle", "laugh"))
			for(var/datum/gas/oxygen_agent_b/agentb in breath.trace_gases)
				if(hallucination < 360)//Max of 6 minutes so dont bother to increase it if they are already past 6
					var/agentb_pp = (agentb.moles/breath.total_moles())*breath_pressure
					if(agentb_pp > 1)
						hallucination += 20
					else
						hallucination += 5//Removed at 2 per tick so this will slowly build up
		//End N2O, AgentB processing
		return 1


	handle_smoke()//Humans can use things like gasmasks to block chemsmoke
		var/block = 0
		if(wear_mask)
			if(wear_mask.flags & BLOCK_GAS_SMOKE_EFFECT)
				block = 1
		if(glasses)
			if(glasses.flags & BLOCK_GAS_SMOKE_EFFECT)
				block = 1
		if(head)
			if(head.flags & BLOCK_GAS_SMOKE_EFFECT)
				block = 1
		if(block)
			return 0
		return ..()


	proc/handle_environment(datum/gas_mixture/environment)
		if(!environment)
			return
		var/loc_temp = T0C
		if(istype(loc, /obj/mecha))
			var/obj/mecha/M = loc
			loc_temp =  M.return_temperature()
		else if(istype(get_turf(src), /turf/space))
			var/turf/heat_turf = get_turf(src)
			loc_temp = heat_turf.temperature
		else if(istype(loc, /obj/machinery/atmospherics/unary/cryo_cell))
			loc_temp = loc:air_contents.temperature
		else
			loc_temp = environment.temperature

		//world << "Loc temp: [loc_temp] - Body temp: [bodytemperature] - Fireloss: [getFireLoss()] - Thermal protection: [get_thermal_protection()] - Fire protection: [thermal_protection + add_fire_protection(loc_temp)] - Heat capacity: [environment_heat_capacity] - Location: [loc] - src: [src]"

		//Body temperature is adjusted in two steps. Firstly your body tries to stabilize itself a bit.
		if(stat != 2)
			stabilize_temperature_from_calories()


		//After then, it reacts to the surrounding atmosphere based on your thermal protection
		var/thermal_protection = get_thermal_protection(loc_temp) //This returns a 0 - 1 value, which corresponds to the percentage of protection based on what you're wearing and what you're exposed to.

		if(thermal_protection < 1)
			bodytemperature += min((1-thermal_protection) * ((loc_temp - bodytemperature) / BODYTEMP_DIVISOR), BODYTEMP_CHANGE_MAX)

		// +/- 50 degrees from 310.15K is the 'safe' zone, where no damage is dealt.
		if(bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)
			//Body temperature is too hot.
			fire_alert = max(fire_alert, 1)
			switch(bodytemperature)
				if(360 to 400)
					deal_damage(HEAT_DAMAGE_LEVEL_1, BURN, null, random_zone())//This might have to move to using the overall damage
					fire_alert = max(fire_alert, 2)
				if(400 to 1000)
					deal_damage(HEAT_DAMAGE_LEVEL_2, BURN, null, random_zone())
					fire_alert = max(fire_alert, 2)
				if(1000 to INFINITY)
					deal_damage(HEAT_DAMAGE_LEVEL_3, BURN, null, random_zone())
					fire_alert = max(fire_alert, 2)

		else if(bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT)
			fire_alert = max(fire_alert, 1)
			if(!istype(loc, /obj/machinery/atmospherics/unary/cryo_cell))
				switch(bodytemperature)
					if(200 to 260)
						deal_damage(COLD_DAMAGE_LEVEL_1, BURN, null, random_zone())
						fire_alert = max(fire_alert, 1)
					if(120 to 200)
						deal_damage(COLD_DAMAGE_LEVEL_1, BURN, null, random_zone())
						fire_alert = max(fire_alert, 1)
					if(-INFINITY to 120)
						deal_damage(COLD_DAMAGE_LEVEL_1, BURN, null, random_zone())
						fire_alert = max(fire_alert, 1)

		//Pressure here
		var/pressure = environment.return_pressure()
		var/adjusted_pressure = calculate_affecting_pressure(pressure) //Returns how much pressure actually affects the mob.
		switch(adjusted_pressure)
			if(HAZARD_HIGH_PRESSURE to INFINITY)
				if(oxy_damage < 60)
					deal_damage(min(((adjusted_pressure / HAZARD_HIGH_PRESSURE) -1)*PRESSURE_DAMAGE_COEFFICIENT , MAX_HIGH_PRESSURE_DAMAGE), OXY)
				else
					deal_damage(min(((adjusted_pressure / HAZARD_HIGH_PRESSURE) -1)*PRESSURE_DAMAGE_COEFFICIENT , MAX_HIGH_PRESSURE_DAMAGE), BRUTE)
				pressure_alert = 2


			if(WARNING_HIGH_PRESSURE to HAZARD_HIGH_PRESSURE)
				pressure_alert = 1
			if(WARNING_LOW_PRESSURE to WARNING_HIGH_PRESSURE)
				pressure_alert = 0
			if(HAZARD_LOW_PRESSURE to WARNING_LOW_PRESSURE)
				pressure_alert = -1
			else
				if(oxy_damage < 60)
					deal_damage(LOW_PRESSURE_DAMAGE, OXY)
				else
					deal_damage(LOW_PRESSURE_DAMAGE, BRUTE)
				pressure_alert = -2
		return


	calculate_affecting_pressure(var/pressure)
		var/pressure_difference = abs( pressure - ONE_ATMOSPHERE )
		var/pressure_adjustment_coefficient = 1 - get_pressure_protection(pressure)	//Determins how much the clothing you are wearing protects you in percent.
		pressure_adjustment_coefficient = max(pressure_adjustment_coefficient,0) //So it isn't less than 0
		pressure_difference = pressure_difference * pressure_adjustment_coefficient
		if(pressure > ONE_ATMOSPHERE)
			return ONE_ATMOSPHERE + pressure_difference
		else
			return ONE_ATMOSPHERE - pressure_difference


	proc/get_pressure_protection(var/pressure)
		if(PRESSURE_RESIST in mutations)
			return 1 //Fully protected from the pressure.
		var/suit_protection = 0
		var/head_protection = 0
		if(head && (head.max_pressure >= pressure && head.min_pressure <= pressure))
			if(head.body_parts_covered & HEAD)
				head_protection += CLOTHING_PROTECTION_HEAD
			if(head.body_parts_covered & CHEST)
				head_protection += CLOTHING_PROTECTION_TORSO
			if(head.body_parts_covered & LEGS)
				head_protection += CLOTHING_PROTECTION_LEGS
			if(head.body_parts_covered & ARMS)
				head_protection += CLOTHING_PROTECTION_ARMS
		if(wear_mask && head_protection < CLOTHING_PROTECTION_MASK)//If our head protection sucks then see if we have a gasmask on
			if(istype(wear_mask,/obj/item/clothing/mask/gas))
				head_protection = CLOTHING_PROTECTION_MASK
		if(wear_suit && (wear_suit.max_pressure >= pressure && wear_suit.min_pressure <= pressure))
			if(wear_suit.body_parts_covered & HEAD)
				suit_protection += CLOTHING_PROTECTION_HEAD
			if(wear_suit.body_parts_covered & CHEST)
				suit_protection += CLOTHING_PROTECTION_TORSO
			if(wear_suit.body_parts_covered & LEGS)
				suit_protection += CLOTHING_PROTECTION_LEGS
			if(wear_suit.body_parts_covered & ARMS)
				suit_protection += CLOTHING_PROTECTION_ARMS
		if(suit_protection && head_protection)//Only grant protection if BOTH the head and at least part of the body is covered
			return suit_protection + head_protection
		return 0

	proc/stabilize_temperature_from_calories()
		switch(bodytemperature)
			if(-INFINITY to 220.15) //now at 220 to see if you will take damage properly //260.15 is 310.15 - 50, the temperature where you start to feel effects.
				if(nutrition >= 2) //If we are very, very cold we'll use up quite a bit of nutriment to heat us up.
					nutrition -= 2
				var/body_temperature_difference = 310.15 - bodytemperature
				bodytemperature += max((body_temperature_difference / BODYTEMP_AUTORECOVERY_DIVISOR), BODYTEMP_AUTORECOVERY_MINIMUM)
			if(260.15 to 360.15)
				var/body_temperature_difference = 310.15 - bodytemperature
				bodytemperature += body_temperature_difference / BODYTEMP_AUTORECOVERY_DIVISOR
			if(360.15 to INFINITY) //360.15 is 310.15 + 50, the temperature where you start to feel effects.
				var/body_temperature_difference = 310.15 - bodytemperature
				bodytemperature += min((body_temperature_difference / BODYTEMP_AUTORECOVERY_DIVISOR), -BODYTEMP_AUTORECOVERY_MINIMUM)	//We're dealing with negative numbers
		return


	proc/get_thermal_protection(temperature)
		if(TEMPATURE_RESIST in mutations)
			return 1 //Fully protected from the cold.
		var/suit_protection = 0
		var/head_protection = 0
		if(head)
			if(head.max_temperature && head.max_temperature >= temperature)
				if(head.body_parts_covered & HEAD)
					head_protection += CLOTHING_PROTECTION_HEAD
				if(head.body_parts_covered & CHEST)
					head_protection += CLOTHING_PROTECTION_TORSO
				if(head.body_parts_covered & LEGS)
					head_protection += CLOTHING_PROTECTION_LEGS
				if(head.body_parts_covered & ARMS)
					head_protection += CLOTHING_PROTECTION_ARMS
		if(wear_suit)
			if(wear_suit.max_temperature && wear_suit.max_temperature >= temperature)
				if(wear_suit.body_parts_covered & HEAD)
					suit_protection += CLOTHING_PROTECTION_HEAD
				if(wear_suit.body_parts_covered & CHEST)
					suit_protection += CLOTHING_PROTECTION_TORSO
				if(wear_suit.body_parts_covered & LEGS)
					suit_protection += CLOTHING_PROTECTION_LEGS
				if(wear_suit.body_parts_covered & ARMS)
					suit_protection += CLOTHING_PROTECTION_ARMS
		return suit_protection + head_protection


	proc/handle_chemicals_in_body()
		if(reagents) reagents.metabolize(src)

		if(dna && dna.mutantrace == "plant") //couldn't think of a better place to place it, since it handles nutrition -- Urist
			var/light_amount = 0 //how much light there is in the place, affects receiving nutrition and healing
			if(isturf(loc)) //else, there's considered to be no light
				var/turf/T = loc
				var/area/A = T.loc
				if(A)
					if(A.lighting_use_dynamic)	light_amount = min(10,T.lighting_lumcount) - 5 //hardcapped so it's not abused by having a ton of flashlights
					else						light_amount =  5
			nutrition += light_amount
			if(nutrition > 500)
				nutrition = 500
			if(light_amount > 2) //if there's enough light, heal
				deal_damage(-1, BRUTE)
				deal_damage(-1, BURN)
				deal_damage(-1, TOX)
				deal_damage(-1, OXY)
		if(dna && dna.mutantrace == "shadow")
			var/light_amount = 0
			if(isturf(loc))
				var/turf/T = loc
				var/area/A = T.loc
				if(A)
					if(A.lighting_use_dynamic)	light_amount = T.lighting_lumcount
					else						light_amount =  10
			if(light_amount > 2) //if there's enough light, start dying
				deal_damage(2, BURN)
			else if(light_amount < 2) //heal in the dark
				deal_damage(-1, BRUTE)
				deal_damage(-1, BURN)
				deal_damage(-1, TOX)
				deal_damage(-1, OXY)

		//The fucking FAT mutation is the dumbest shit ever. It makes the code so difficult to work with
		if(FAT in mutations)
			if(overeatduration < 100)
				src << "\blue You feel fit again!"
				mutations.Remove(FAT)
				update_mutantrace(0)
				update_mutations(0)
				update_inv_w_uniform(0)
				update_inv_wear_suit()
		else
			if(overeatduration > 500)
				src << "\red You suddenly feel blubbery!"
				mutations.Add(FAT)
				update_mutantrace(0)
				update_mutations(0)
				update_inv_w_uniform(0)
				update_inv_wear_suit()

		// nutrition decrease
		if (nutrition > 0 && stat != 2)
			nutrition = max (0, nutrition - HUNGER_FACTOR)

		if (nutrition > 450)
			if(overeatduration < 600) //capped so people don't take forever to unfat
				overeatduration++
		else
			if(overeatduration > 1)
				overeatduration -= 2 //doubled the unfat rate

		if(dna && dna.mutantrace == "plant")
			if(nutrition < 200)
				deal_damage(2, BRUTE)

		if (drowsyness)
			drowsyness--
			eye_blurry = max(2, eye_blurry)
			if (prob(5))
				sleeping += 1
				deal_damage(5, PARALYZE)

		confused = max(0, confused - 1)
		// decrement dizziness counter, clamped to 0
		if(resting)
			dizziness = max(0, dizziness - 15)
			jitteriness = max(0, jitteriness - 15)
		else
			dizziness = max(0, dizziness - 3)
			jitteriness = max(0, jitteriness - 3)
		return //TODO: DEFERRED


	proc/handle_regular_status_updates()
		if(stat == DEAD)	//DEAD. BROWN BREAD. SWIMMING WITH THE SPESS CARP
			blinded = 1
			silent = 0
		else				//ALIVE. LIGHTS ARE ON
			update_health()	//TODO
			if(health <= config.health_threshold_dead || !getbrain(src) || !getheart(src))
				death()
				blinded = 1
				silent = 0
				return 1

			//UNCONSCIOUS. NO-ONE IS HOME
			if((oxy_damage > 50) || (config.health_threshold_crit > health))
				deal_damage(3, PARALYZE)

			if(!hallucination)
				hallucination = -1
				for(var/atom/a in hallucinations)
					del a
			if(hallucination >= 20)
				if(prob(3))
					fake_attack(src)
				if(!handling_hal)
					spawn handle_hallucinations() //The not boring kind!
			if(hallucination)
				hallucination = max(hallucination - 2, 0)

			if(fatigue > 100 && !paralysis)
				src << "<span class='notice'>You're too tired to keep going...</span>"
				for(var/mob/O in oviewers(src, null))
					O.show_message("<B>[src]</B> slumps to the ground, too tired to continue moving.", 1)
				deal_damage(6, PARALYZE)
				deal_damage(-10, FATIGUE)

			if(paralysis)
				deal_damage(-1, PARALYZE)
				blinded = 1
				stat = UNCONSCIOUS
			else if(sleeping)
				handle_dreams()
				deal_damage(-10, FATIGUE)
				sleeping = max(sleeping-1, 0)
				blinded = 1
				stat = UNCONSCIOUS
				if(prob(10) && health && !hal_crit )
					spawn(0)
						emote("snore")
			//CONSCIOUS
			else
				stat = CONSCIOUS

			//Eyes
			if(sdisabilities & BLIND)	//disabled-blind, doesn't get better on its own
				blinded = 1
			else if(eye_blind)			//blindness, heals slowly over time
				eye_blind = max(eye_blind-1,0)
				blinded = 1
			else if(istype(glasses, /obj/item/clothing/glasses/sunglasses/blindfold))	//resting your eyes with a blindfold heals blurry eyes faster
				eye_blurry = max(eye_blurry-3, 0)
				blinded = 1
			else if(eye_blurry)	//blurry eyes heal slowly
				eye_blurry = max(eye_blurry-1, 0)

			//Ears
			if(sdisabilities & DEAF)	//disabled-deaf, doesn't get better on its own
				ear_deaf = max(ear_deaf, 1)
			else if(ear_deaf)			//deafness, heals slowly over time
				ear_deaf = max(ear_deaf-1, 0)
			else if(istype(ears, /obj/item/clothing/ears/earmuffs))	//resting your ears with earmuffs heals ear damage faster
				ear_deaf = max(ear_deaf, 1)

			//Other
			if(weakened)
				weakened = max(weakened-1,0)	//before you get mad Rockdtben: I done this so update_canmove isn't called multiple times

			if(stuttering)
				stuttering = max(stuttering-1, 0)

			if(silent)
				silent = max(silent-1, 0)

			if(druggy)
				druggy = max(druggy-1, 0)
		return 1


	proc/handle_regular_hud_updates()
		if(!client)	return 0

		for(var/image/hud in client.images)
			if(copytext(hud.icon_state,1,4) == "hud") //ugly, but icon comparison is worse, I believe
				client.images.Remove(hud)

		client.screen.Remove(global_hud.blurry, global_hud.druggy, global_hud.vimpaired, global_hud.darkMask)

		update_action_buttons()

		if(damageoverlay.overlays)
			damageoverlay.overlays = list()

		if(stat == UNCONSCIOUS)
			//Critical damage passage overlay
			if(health <= 0)
				var/image/I
				switch(health)
					if(-20 to -10)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage1")
					if(-30 to -20)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage2")
					if(-40 to -30)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage3")
					if(-50 to -40)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage4")
					if(-60 to -50)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage5")
					if(-70 to -60)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage6")
					if(-80 to -70)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage7")
					if(-90 to -80)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage8")
					if(-95 to -90)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage9")
					if(-INFINITY to -95)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "passage10")
				damageoverlay.overlays += I
		else
			//Oxygen damage overlay
			if(oxy_damage)
				var/image/I
				switch(oxy_damage)
					if(10 to 20)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "oxydamageoverlay1")
					if(20 to 25)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "oxydamageoverlay2")
					if(25 to 30)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "oxydamageoverlay3")
					if(30 to 35)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "oxydamageoverlay4")
					if(35 to 40)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "oxydamageoverlay5")
					if(40 to 45)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "oxydamageoverlay6")
					if(45 to INFINITY)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "oxydamageoverlay7")
				damageoverlay.overlays += I

			//Fire and Brute damage overlay (BSSR)
			var/hurtdamage = src.get_brute_loss() + src.get_fire_loss() + damageoverlaytemp
			damageoverlaytemp = 0 // We do this so we can detect if someone hits us or not.
			if(hurtdamage)
				var/image/I
				switch(hurtdamage)
					if(10 to 25)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "brutedamageoverlay1")
					if(25 to 40)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "brutedamageoverlay2")
					if(40 to 55)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "brutedamageoverlay3")
					if(55 to 70)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "brutedamageoverlay4")
					if(70 to 85)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "brutedamageoverlay5")
					if(85 to INFINITY)
						I = image("icon" = 'icons/mob/screen1_full.dmi', "icon_state" = "brutedamageoverlay6")
				damageoverlay.overlays += I

		if( stat == DEAD )
			sight |= (SEE_TURFS|SEE_MOBS|SEE_OBJS)
			see_in_dark = 8
			if(!druggy)		see_invisible = SEE_INVISIBLE_LEVEL_TWO
			if(healths)		healths.icon_state = "health7"	//DEAD healthmeter
		else
			sight &= ~(SEE_TURFS|SEE_MOBS|SEE_OBJS)
			if(dna)
				switch(dna.mutantrace)
					if("lizard","slime")
						see_in_dark = 3
						see_invisible = SEE_INVISIBLE_LEVEL_ONE
					if("shadow")
						see_in_dark = 8
					else
						see_in_dark = 2

			if(XRAY in mutations)
				sight |= SEE_TURFS|SEE_MOBS|SEE_OBJS
				see_in_dark = 8
				if(!druggy)		see_invisible = SEE_INVISIBLE_LEVEL_TWO

			if(seer)
				var/obj/effect/rune/R = locate() in loc
				if(R && R.word1 == wordsee && R.word2 == wordhell && R.word3 == wordjoin)
					see_invisible = SEE_INVISIBLE_OBSERVER
				else
					see_invisible = SEE_INVISIBLE_LIVING
					seer = 0

			if(istype(wear_mask, /obj/item/clothing/mask/gas/voice/space_ninja))
				var/obj/item/clothing/mask/gas/voice/space_ninja/O = wear_mask
				switch(O.mode)
					if(0)
						var/target_list[] = list()
						for(var/mob/living/target in oview(src))
							if( target.mind&&(target.mind.special_role||issilicon(target)) )//They need to have a mind.
								target_list += target
						if(target_list.len)//Everything else is handled by the ninja mask proc.
							O.assess_targets(target_list, src)
						if(!druggy)		see_invisible = SEE_INVISIBLE_LIVING
					if(1)
						see_in_dark = 5
						if(!druggy)		see_invisible = SEE_INVISIBLE_LIVING
					if(2)
						sight |= SEE_MOBS
						if(!druggy)		see_invisible = SEE_INVISIBLE_LEVEL_TWO
					if(3)
						sight |= SEE_TURFS
						if(!druggy)		see_invisible = SEE_INVISIBLE_LIVING

			if(glasses)
				if(istype(glasses, /obj/item/clothing/glasses/meson))
					sight |= SEE_TURFS
					if(!druggy)
						see_invisible = SEE_INVISIBLE_MINIMUM
				else if(istype(glasses, /obj/item/clothing/glasses/night))
					see_in_dark = 5
					if(!druggy)
						see_invisible = SEE_INVISIBLE_MINIMUM
				else if(istype(glasses, /obj/item/clothing/glasses/thermal))
					sight |= SEE_MOBS
					if(!druggy)
						see_invisible = SEE_INVISIBLE_MINIMUM
				else if(istype(glasses, /obj/item/clothing/glasses/material))
					sight |= SEE_OBJS
					if(!druggy)
						see_invisible = SEE_INVISIBLE_MINIMUM

	/* HUD shit goes here, as long as it doesn't modify sight flags */
	// The purpose of this is to stop xray and w/e from preventing you from using huds -- Love, Doohl

				else if(istype(glasses, /obj/item/clothing/glasses/sunglasses))
					see_in_dark = 1
					if(istype(glasses, /obj/item/clothing/glasses/sunglasses/sechud))
						var/obj/item/clothing/glasses/sunglasses/sechud/O = glasses
						if(O.hud)		O.hud.process_hud(src)
						if(!druggy)		see_invisible = SEE_INVISIBLE_LIVING

				else if(istype(glasses, /obj/item/clothing/glasses/hud))
					var/obj/item/clothing/glasses/hud/O = glasses
					O.process_hud(src)
					if(!druggy)
						see_invisible = SEE_INVISIBLE_LIVING
				else
					see_invisible = SEE_INVISIBLE_LIVING
			else
				see_invisible = SEE_INVISIBLE_LIVING

			if(healths)
				switch(hal_screwyhud)
					if(1)	healths.icon_state = "health6"
					if(2)	healths.icon_state = "health7"
					else
						switch(health - fatigue)
							if(100 to INFINITY)		healths.icon_state = "health0"
							if(80 to 100)			healths.icon_state = "health1"
							if(60 to 80)			healths.icon_state = "health2"
							if(40 to 60)			healths.icon_state = "health3"
							if(20 to 40)			healths.icon_state = "health4"
							if(0 to 20)				healths.icon_state = "health5"
							else					healths.icon_state = "health6"

			if(nutrition_icon)
				switch(nutrition)
					if(450 to INFINITY)				nutrition_icon.icon_state = "nutrition0"
					if(350 to 450)					nutrition_icon.icon_state = "nutrition1"
					if(250 to 350)					nutrition_icon.icon_state = "nutrition2"
					if(150 to 250)					nutrition_icon.icon_state = "nutrition3"
					else							nutrition_icon.icon_state = "nutrition4"

			if(pressure)
				pressure.icon_state = "pressure[pressure_alert]"

			if(pullin)
				if(pulling)								pullin.icon_state = "pull1"
				else									pullin.icon_state = "pull0"
//			if(rest)	//Not used with new UI
//				if(resting || lying || sleeping)		rest.icon_state = "rest1"
//				else									rest.icon_state = "rest0"
			if(toxin)
				if(hal_screwyhud == 4 || toxins_alert)	toxin.icon_state = "tox1"
				else									toxin.icon_state = "tox0"
			if(oxygen)
				if(hal_screwyhud == 3 || oxygen_alert)	oxygen.icon_state = "oxy1"
				else									oxygen.icon_state = "oxy0"
			if(fire)
				if(fire_alert)							fire.icon_state = "fire[fire_alert]" //fire_alert is either 0 if no alert, 1 for cold and 2 for heat.
				else									fire.icon_state = "fire0"

			if(bodytemp)
				switch(bodytemperature) //310.055 optimal body temp
					if(370 to INFINITY)		bodytemp.icon_state = "temp4"
					if(350 to 370)			bodytemp.icon_state = "temp3"
					if(335 to 350)			bodytemp.icon_state = "temp2"
					if(320 to 335)			bodytemp.icon_state = "temp1"
					if(300 to 320)			bodytemp.icon_state = "temp0"
					if(295 to 300)			bodytemp.icon_state = "temp-1"
					if(280 to 295)			bodytemp.icon_state = "temp-2"
					if(260 to 280)			bodytemp.icon_state = "temp-3"
					else					bodytemp.icon_state = "temp-4"

			if(blind)
				if(blinded)		blind.layer = 18
				else			blind.layer = 0

			if( disabilities & NEARSIGHTED && !istype(glasses, /obj/item/clothing/glasses/regular) )
				client.screen += global_hud.vimpaired
			if(eye_blurry)			client.screen += global_hud.blurry
			if(druggy)				client.screen += global_hud.druggy

			var/masked = 0

			if( istype(head, /obj/item/clothing/head/welding) )
				var/obj/item/clothing/head/welding/O = head
				if(!O.up)
					client.screen += global_hud.darkMask
					masked = 1

			if(!masked && istype(glasses, /obj/item/clothing/glasses/welding) )
				var/obj/item/clothing/glasses/welding/O = glasses
				if(!O.up)
					client.screen += global_hud.darkMask

			if(eye_stat > 20)
				if(eye_stat > 30)	client.screen += global_hud.darkMask
				else				client.screen += global_hud.vimpaired

			if(machine)
				if(!machine.check_eye(src))		reset_view(null)
			else
				if(!client.adminobs)			reset_view(null)
		return 1


	proc/handle_random_events()
		// Puke if toxloss is too high
		if(!stat)
			if (tox_damage >= 45 && nutrition > 20)
				lastpuke ++
				if(lastpuke >= 25) // about 25 second delay I guess
					for(var/mob/O in viewers(world.view, src))
						O.show_message(text("<b>\red [] throws up!</b>", src), 1)
					playsound(loc, 'sound/effects/splat.ogg', 50, 1)

					var/turf/location = loc
					if (istype(location, /turf/simulated))
						location.add_vomit_floor(src, 1)

					nutrition -= 20
					deal_damage(-3, TOX)

					// make it so you can only puke so fast
					lastpuke = 0

		//0.1% chance of playing a scary sound to someone who's in complete darkness
		if(isturf(loc) && rand(1,1000) == 1)
			var/turf/currentTurf = loc
			if(!currentTurf.lighting_lumcount)
				playsound_local(src,pick(scarySounds),50, 1, -1)


	proc/handle_changeling()
		if(mind && mind.changeling)
			mind.changeling.regenerate()

#undef HUMAN_MAX_OXYLOSS
#undef HUMAN_CRIT_MAX_OXYLOSS