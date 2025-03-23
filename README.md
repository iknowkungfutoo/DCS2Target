# What Is DCS2TARGET?

With the recent release of the new Thrustmaster Viper Mission Pack and Viper Panel, many users have shared their dismay that the landing gear and other indicators are not working/integrated with DCS. This isn't a fault of the product or Thrustmaster as there are far too many applications, each with their unique style of exposing simulation data. It isn't fair to expect Thrustmaster to support all of those applications and this is where the community fills the gap.

Along with dcs2target, you will also need [TMHotasLEDSync](https://github.com/iknowkungfutoo/TMHotasLEDSync). Together, they enable the LEDs on the Viper Mission Pack, Viper Panel, and Warthog to relay the indicators in the DCS cockpits. There is a caveat, though, as I will explain below.

For the Viper Mission Pack and Viper Panel, some LEDs can be used to relay the indicators of the F-16 landing gear, the landing gear handle and the threat warning auxiliary panel. It also has two columns of five user-programmable LEDs. However, the LEDs in the threat warning auxiliary switches do not fully mimic those of the real aircraft. Specifically, the "altitude" switch can either be illuminated red or green on the Viper Mission Pack / Panel as opposed to "LOW" in amber and "ALT" in green. Also, the ACT/PWR switch can only be illuminated fully instead of individually for "S" and "POWER". Therefore, we have to accept some compromises regarding how the indicators of the F-16 can be shown on the Viper Mission Pack / Panel.

For the Warthog, there is only a column of five LEDs for the user to configure.

# How It Works:

The dcs2target.zip file contains a set of lua files that interrogate DCS and send the relevant lamp data to the Thrustmaster TARGET software running the TMHotasLEDSync.tmc script. Data is sent via TCP only if the simulation data changes. The TARGET script handles each packet through an event, so it is fairly efficient and should not introduce any significant load on your CPU.

The DCS simulation data is interrogated every 100ms (that’s ten times a second). It’s not too taxing on the system yet fast enough so that we humans shouldn’t notice any lag.

The TARGET script does not configure your HOTAS throttle for use with DCS. It merely controls the LEDs of the HOTAS throttle. If you use another TARGET script to map your device to DCS, I advise you to use DCS to map the axis, buttons and switches instead. However, if you wish to use a TARGET script to map your HOTAS throttle to DCS, you’ll have to try to figure out how to combine this script with yours. Please don’t ask me to help combine scripts; you’ll have to figure that out yourself.

# Installation:

The dcs2target.zip file contains two folders: Hooks and dcs2target. Extract the folders and save them in the "%HOMEPATH%\Saved Games\DCS\Scripts" or "%HOMEPATH%\Saved Games\DCS.openbeta\Scripts" folder or both if you use both stable and open beta builds.
Your "%HOMEPATH%\Saved Games\DCS\Scripts" and "Saved Games\DCS.openbeta\Scripts" folders should now have two folders:

1. Hooks
2. dcs2export

Unzip the [TMHotasLEDSync.zip](https://github.com/iknowkungfutoo/TMHotasLEDSync) file to a folder of your choosing.

# How To Use:

1. Start the Thrustmaster T.A.R.G.E.T. script editor.
2. Open the TMHotasLEDSync.tmc script from the folder where you extracted TMHotasLEDSync.zip.
3. Start the script.
4. Start DCS.

# Supported Aircraft:

The following aircraft are currently supported:

| AIRCRAFT | EXPORTED PARAMETERS | SUPPORTED TM HOTAS THROTTLE |
|------------|-----------------------------------------------------------------|-------------------------------|
| A-10C | Speed brake position and console lighting. | Warthog |
| A-10C_2 | Speed brake position and console lighting. | Warthog |
| F-16 | Gear, gear warning, TWA indications, JFS RUN, MAIN GEN, STBY GEN, FLCS RLY, EPU RUN and the speed brake position. | Viper Mission Pack, Viper Panel |
| FA-18_Hornet | Speed brake position, console lighting, APU RUN and Gear Handle lamp. | Warthog |
| JF-17 | Gear, gear warning, gear transit, master warning and the speed brake position. | Viper Mission Pack, Viper Panel |
| Su-25T |Speed brake position. | Warthog |
| Su-33 |Speed brake position. | Warthog |

# Suggestions And Feature Requests:

Feel free to make any suggestions for improvements on [dcs2target DCS thread](https://forum.dcs.world/topic/338119-dcs2target-dcs-to-thrustmaster-hotas-led-controller-viper-mission-pack-viper-panel-and-warthog/#comments) or [here](https://github.com/iknowkungfutoo/DCS2Target/discussions).

# Need Help?

In the first instance, ensure you have installed v3.0.24.618_rev1 or later of the Thrustmaster TARGET software. Most problems are caused by people running old versions of the software.
If that does not solve your problem, raise an issue on the [dcs2target DCS thread](https://forum.dcs.world/topic/338119-dcs2target-dcs-to-thrustmaster-hotas-led-controller-viper-mission-pack-viper-panel-and-warthog/#comments) or [here](https://github.com/iknowkungfutoo/DCS2Target/issues). Include your dcs.log and TARGET script editor console output in your message (you can select, copy and paste directly from the TARGET console output using your mouse).


