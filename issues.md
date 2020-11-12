Export of Github issues for [HaddingtonDynamics/Dexter](https://github.com/HaddingtonDynamics/Dexter).

# [\#108 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/108) `closed`: Onboard kinematics 'M' move_to and 'T' move_to_straight commands accept only integer orientation values
**Labels**: `Firmware`, `bug`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-10-23 20:27](https://github.com/HaddingtonDynamics/Dexter/issues/108):

While parsing the values for the orientation in movements using onboard kinematics, the my_dir and my_dir_end vectors were being taken as integers instead of floats. Thank you Edgaras for reporting this issue! 

This has been corrected by the following update:

https://github.com/HaddingtonDynamics/Dexter/commit/5900820df553f8c5df0e71928b9b46827b642c9b




-------------------------------------------------------------------------------

# [\#107 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/107) `open`: Support OpenMV Camera 
**Labels**: `Documentation`, `Hardware`, `communication`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-10-09 20:13](https://github.com/HaddingtonDynamics/Dexter/issues/107):

A few notes:

When connected to Dexter, it shows up as a `/dev/ttyACM#` where number starts a 0, then 1, etc... depending on the number of devices connected. SSH into Dexter, do an `ls /dev/tty*` with the device disconnected, then connect, do the command again, and notice the difference.

Connect at 115200 N 8 1 This works to test connectivity:
```
stty -echo -F /dev/ttyACM0 ospeed 115200 ispeed 115200 raw
cat -v < /dev/ttyACM0 & cat > /dev/ttyACM0
```
enter Ctrl+C to stop, then `fg 1` and Ctrl+C again. For more on serial interface, see:
https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Serial-Peripherals

When connected, press Ctrl+C to stop any running program ( works nicely from PuTTY, but you can't do this from the cat trick shown above need to find a work around, probably `echo $\cc>/dev/ttyACM0`), Ctrl+D to reload / sync the files from the file folder, and `import main` to run the main.py file from the folder. 

To find and mount the flash drive to re-program the OpenMV cam, you can use `blkid` to show available block devices without the device connected, then connect it and use the command again. The new device is the camera. It will probably appear as `/dev/sda1: SEC_TYPE="msdos" UUID="4621-0000" TYPE="vfat"`. To access the contents, make a folder: `mkdir /mnt/openmvcam` then mount the device: `sudo mount /dev/sda1 /mnt/openmvcam/` and the files will appear at `/mnt/openmvcam`. Edit `main.py` to change the cameras code. When finished, be sure to `umount /mnt/openmvcam`

Again, Ctrl+D causes the camera to reset and reload the file from the drive if you are connected via the serial terminal. Then you can type `import main` to run it. Ctrl+C to break it. 

The following program allows you to ask the Camera to look for a number of things. For a Job Engine program to interface with this see:
https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-605376411

```python
import sensor, image, time, math, ubinascii
from pyb import USB_VCP

orange_threshold =( 18, 69, 40, 86, 0, 72)
orange_blob_pixel_thres = 50

q_tip_threshold =( 192, 255)
q_tip_width_min = 12 #decrease if more than ~8" away
q_tip_height_min = 30 #decrease if more than ~8" away or tilted > 45'
q_tip_width_max = 21 #increase if closer than ~6" or tilted > 45'
q_tip_height_max = 40 #increase if closer than ~6"
q_tip_area_min = q_tip_width_min * q_tip_height_min
q_tip_pixels_min = int(q_tip_area_min * 0.7)
q_tip_pixel_max = 0.9 #some pixels must be black, no rectangles
setup_delay = 200

sensor.reset() # Initialize the camera
mode = b'?' #default starting mode. Provide correct setup for this mode here:
#sensor.set_pixformat(sensor.RGB565) # Set pixel format to RGB565 (or GRAYSCALE)
sensor.set_pixformat(sensor.GRAYSCALE)
sensor.set_framesize(sensor.QVGA) # QVGA (320x240) for more accurate length detection
sensor.set_auto_whitebal(True)
sensor.skip_frames(time = setup_delay)
clock = time.clock() # Tracking frame rate
#take a starting picture to define img
img = sensor.snapshot().compress()

f_x = (2.8 / 3.984) * 160 # find_apriltags defaults to this if not set
f_y = (2.8 / 2.952) * 120 # find_apriltags defaults to this if not set
c_x = 160 * 0.5 # find_apriltags defaults to this if not set (the image.w * 0.5)
c_y = 120 * 0.5 # find_apriltags defaults to this if not set (the image.h * 0.5)

# barcode type lookup table
barcode_type = {
    image.EAN2: "EAN2",
    image.EAN5: "EAN5",
    image.EAN8: "EAN8",
    image.UPCE: "UPCE",
    image.ISBN10: "ISBN10",
    image.EAN13: "EAN13",
    image.ISBN13: "ISBN13",
    image.I25: "I25",
    image.DATABAR: "DATABAR",
    image.DATABAR_EXP: "DATABAR_EXP",
    image.CODABAR: "CODABAR",
    image.CODE39: "CODE39",
    image.PDF417: "PDF417",
    image.CODE93: "CODE93",
    image.CODE128: "CODE128"
}

def barcode_name(code):
    # if the code type is in the dictionary, return the value string
    if code.type() in barcode_type.keys():
        return barcode_type[code.type()]
    # otherwise return a "not defined" string
    return "NOT DEFINED"

idno = "0"
try:
    idno = open('/id.txt').read()
except:
    print("[{\"error\":\"id not set in id.txt file\"}]")

usb = USB_VCP()

while(True):
    clock.tick() # Track elapsed milliseconds between snapshots().

    #ID
    cmd = usb.recv(1, timeout=10)
    if (cmd != mode):
        if (cmd == b'!'): #setup AND take a picture
            #sensor.set_pixformat(sensor.RGB565) # Set pixel format to RGB565 (or GRAYSCALE)
            #sensor.set_framesize(sensor.QVGA)   # Set frame size to QVGA (320x240)
            #sensor.skip_frames(time = 2000)     # Wait for settings take effect.
            #img = sensor.snapshot().compress()
            shrink = 50
            if (mode == b'b'): #barcode image is too big
                shrink = 20 #need to shrink it more
            img_data = str(ubinascii.b2a_base64(img.compress(shrink)))[1:]
            print("[{\"image_length\":"+str(img.size())+", \"data\":"+img_data+"}]")
            sensor.skip_frames(time = 2000)     # Wait for data to xmit
            cmd = mode #continue on in the same mode

        if (cmd == b'a'): #setup to look for April Tags
            #presetting for april tags does NOT work. Always errors over memory allocation.
            sensor.set_pixformat(sensor.GRAYSCALE)
            sensor.set_framesize(sensor.QQVGA) # QQVGA 160x120 faster
            sensor.skip_frames(time = setup_delay)
            #print("[{\"mode\":\"april tag\"}]")

        if (cmd == b'b'): #setup for Bar Codes
            sensor.set_pixformat(sensor.GRAYSCALE)
            sensor.set_framesize(sensor.VGA) #VGA 640x480
            #sensor.set_windowing((640, 240))
            sensor.set_auto_gain(False)
            sensor.set_auto_whitebal(False)
            sensor.skip_frames(time = setup_delay)

        if (cmd == b'o'): #setup for orange object
            sensor.set_pixformat(sensor.RGB565) # Format is RGB565.
            sensor.set_framesize(sensor.QQVGA) # QQVGA 160x120 faster
            sensor.set_auto_gain(False) # Turn off automatic auto gain.
            #By default, in color recognition, be sure to turn off white balance.
            sensor.set_auto_whitebal(False)
            sensor.skip_frames(time = setup_delay)

        if (cmd == b'q'): #setup for q-tips
            sensor.set_pixformat(sensor.GRAYSCALE)
            sensor.set_framesize(sensor.QVGA) # QVGA (320x240) for length detection
            #sensor.set_auto_whitebal(False) #This helps with light level variation
            sensor.skip_frames(time = setup_delay)


        if (cmd > b' '): # generally, just set to the mode to any valid command.
            mode = cmd

    sensor.skip_frames(time = 100) # Wait a titch so we don't jam up the queue

    if (mode == b'?'):
        print("[{\"camname\": \""+idno+"\"}]")
        mode = b' '
        continue

    if (mode == b' '): #be quite mode
        sensor.skip_frames(time = 100) # don't overheat
        continue

    if (mode == b'a'): #look for April Tags
        img = sensor.snapshot().lens_corr(1.8)
        april_tags = 0
        april_tags = img.find_apriltags(fx=f_x, fy=f_y, cx=c_x, cy=c_y)
        if len(april_tags) > 0:
            #print("April Tag Found")
            print(april_tags)
        continue

    if (mode == b'b'): #look for Bar Code
        img = sensor.snapshot()
        barcodes = 0
        barcodes = img.find_barcodes()
        if len(barcodes) > 0:
            #print("Bar code found")
            print(barcodes)
            #usb.send(barcodes)
            img.draw_rectangle(barcodes[0].rect(), 127, 4)
            img.draw_rectangle(0,0, 640, 50, 0, 1, True)
            img.draw_string(10, 10, barcodes[0].payload(), 127, 4, 0, 0, False)
        continue

    if (mode == b'o'): #look for Orange Blob
        img = sensor.snapshot()
        orange_blobs = 0
        orange_blobs = img.find_blobs([orange_threshold])
        if len(orange_blobs) > 0:
            #print("orange_blobs found")
            #print(len(orange_blobs))
            size = orange_blobs[0][4]
            #print(size)
            if (size > orange_blob_pixel_thres):
                print(orange_blobs)
                img.draw_rectangle((orange_blobs[0].rect())) # rect
            else:
                img.draw_cross(orange_blobs[0].cx(),orange_blobs[0].cy(), 0, 10, 2) # cx, cy
        continue

    if (mode == b'q'): #look for a q-tip
        img = sensor.snapshot()
        blobs = 0
        blobs = img.find_blobs([q_tip_threshold]
            , area_threshold=q_tip_area_min
            , pixels_threshold=q_tip_pixels_min
            , x_stride = 4
            , y_stride = 2
            ) #look for the stick and tip
        if len(blobs) > 0:
            x = blobs[0][0]
            y = blobs[0][1]
            w = blobs[0][2]
            h = blobs[0][3]
            #a = (math.atan2(h,w)/(2*math.pi))*360
            blobs = img.find_blobs([q_tip_threshold]
                , roi=(x,y,w,q_tip_width_min)
                , area_threshold=q_tip_width_min*q_tip_width_min
                , pixels_threshold=int(q_tip_width_min*q_tip_width_min*0.7)
                ) #now just look for the tip
            if len(blobs) > 0:
                img.draw_rectangle(x,y,w,h,color=128,thickness=2) # rect
                #img.draw_rectangle(0,0, 320, 20, 0, 1, True)
                #img.draw_string(10, 10, str(a), 255, 2, 0, 0, False)
                x = blobs[0][0]
                y = blobs[0][1]
                w = blobs[0][2]
                h = blobs[0][3]
                pixels = blobs[0][4]
                if (pixels < int(w * h * q_tip_pixel_max) and
                    w <= q_tip_width_max and
                    w >= q_tip_width_min #and
                    #h <= q_tip_height_max and
                    #h >= q_tip_height_min
                    ):
                    print(blobs)
                    img.draw_rectangle((blobs[0].rect())) # rect
                else:
                    img.draw_cross(blobs[0].cx(), blobs[0].cy(), 0, 10, 2) # cx, cy
            else:
                img.draw_line(x,y,x+w,y+h,0,2)
        continue

    #If nothing else
    print("[\"mode\":\"" + str(mode) + "\"]")
    sensor.skip_frames(time = 1000) # Wait so we don't jam up the queue

```

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-10-14 21:49](https://github.com/HaddingtonDynamics/Dexter/issues/107#issuecomment-708679190):

Supporting a single OpenMV cam isn't too hard, given the above. However, supporting multiple cameras at the same time is a bit more difficult. The port on which the device appears is assigned by the OS and we have no control over it. There is no serial number for the device in the port information. 

A great way to know which device is sending information is to assign each device an ID number. You can do this by programming it with a custom program, or by simply adding this to your program:
````python
idno = "0"
try:
    idno = open('/id.txt').read()
except:
    print("[{\"error\":\"id not set in id.txt file\"}]")
````
And place a file named id.txt in the cameras flash drive with whatever id you like as the contents of the file. Then the ID numbers can easily be changed in the field.

Then the device can be asked to identify itself, or start off by sending it's ID over and over on power up until it's told to send something else.

But what if you don't want to send commands to the device, and just want it to return the device ID along with the data coming back? e.g. if you do blob detection or read a barcode, and you are already printing that object out as JSON to Dexter, wouldn't it be great to just add the ID number of the device into that string? Sadly, these are built in objects (blob, barcode, april_tag, etc...) and it is totally impossible to:
1. Add an attribute to a built in object. e.g. "AttributeError: 'blob' object has no attribute 'id'"
2. Extend or change the class from which the built in object is made e.g. "NameError: name 'blob' isn't defined"
3. Edit in ANY way the data contained in the object. e.g. `blobs[0][8] = ido` "TypeError: 'blob' object doesn't support item assignment"

A way to "get 'er done" is to just unpack the data and print your own JSON:
````python
                x = blobs[0].x()
                y = blobs[0].y()
                w = blobs[0].w()
                h = blobs[0].h()
                pixels = blobs[0].pixels()

                print("[{\"id\":"+str(idno)
                    +", \"x\":"+str(x)
                    +", \"y\":"+str(y)
                    +", \"w\":"+str(w)
                    +", \"h\":"+str(h)
                    +"}]")
````

It is possible to make your own object, and you can extract from the main object the items you want and place them in your object. However, this will print as e.g. `<mutobj object at 30006920>` You must provide your own method for printing your object. 

````python
class mutobj(object):
    #def __init__(self, ):
    #    setattr(self, a, v)
    def __str__(self):
        o = []
        for a,v in self.__dict__.items():
            o.append( "\""+a+"\":"+str(v) )
        return "[{" + ", ".join(o) + "}]"
    pass
....
                x = blobs[0].x()
                y = blobs[0].y()
                w = blobs[0].w()
                h = blobs[0].h()
                b = mutobj()
                b.idno = idno; b.x = x; b.y = y; b.w=w; b.h=h
                print(b)

````

Wouldn't it be nice if the constructor for mutobj could take an object to copy, and iterate it's attributes, copying them into itself? Sadly, 
4. the built in objects to not support the `.__dict__` object which appears to be how object attribute iteration is done in Python.

Perhaps we could pass in an array of the attributes we want to the mutobj constructor? Nope. 
5. The built in objects don't really have attributes at all. They have array indexes, and methods which return specific indexes in the array. 

So to get an attribute by NAME you would have to send an object with names and indexes. E.g. send me the [0] item and call it "X" e.g.
````python

class mutobj(object):
    def __init__(self, obj, attr):
        for n, i in attr.items():
            setattr(self,n,obj[i])
    def __str__(self):
        o = []
        for a,v in self.__dict__.items():
            o.append( "\""+a+"\":"+str(v) )
        return "[{" + ", ".join(o) + "}]"
    pass
    
blobattr = {"x":0,"y":1,"w":2,"h":3} # etc.. pick the things you want and what to call them.

...

                    b = mutobj(blobs[0], blobattr)
                    b.idno = idno 
                    print(b)
````
which, frankly, is a stupid amount of work to jump through just to get an id back with the data.  It probably takes less ram and fewer cycles to just edit the damn string. e.g.
````python
                    print("[{\"idno\":"+str(idno)+", "+str(blobs)[2:])
````
and that will work with any of the built in objects. It only adds the id to the first returned blob, but the other methods had the same limitation.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-10-18 00:15](https://github.com/HaddingtonDynamics/Dexter/issues/107#issuecomment-711096952):

To interpret the base64 data returned via the lines:
````python
import ubinascii
...
            shrink = 20 #desired compression. Use smaller values if out of memory
            img_data = str(ubinascii.b2a_base64(img.compress(shrink)))[1:]
            print("[{\"image_length\":"+str(img.size())+", \"data\":"+img_data+"}]")
````
in the above camera program when the "!" command is sent, use this javascript routine:
````javascript
function b64toimg(str) {
  return Buffer.from(str, 'base64').toString('binary')
  }
````
but be sure to write the file out with the "ascii" encoding. 
````javascript
write_file("test.jpg", b64toimg(b64img), "ascii")
````
or it won't be a valid image.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 18:01](https://github.com/HaddingtonDynamics/Dexter/issues/107#issuecomment-721886013):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/1)


-------------------------------------------------------------------------------

# [\#106 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/106) `open`: Use prior joint angles to avoid kinematic singularity
**Labels**: `DDE`, `Firmware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-09-29 20:57](https://github.com/HaddingtonDynamics/Dexter/issues/106):

As described in [Kinematic singularities](https://github.com/HaddingtonDynamics/Dexter/wiki/Kinematics#singularities), if there are any infinite number of solutions for a commanded pose, how can Dexter know which one to pick? The obvious answer is that it should pick the one that moves the joints the least, using the context from the prior pose to pick the new pose which is most similar. 

Some work on this has been done in DDE's Kin.js:
https://github.com/cfry/dde/blob/master/math/Kin.js
(search for `.context_inverse_kinematics`)




-------------------------------------------------------------------------------

# [\#105 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/105) `open`: Track total joint movement
**Labels**: `Firmware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-09-22 02:12](https://github.com/HaddingtonDynamics/Dexter/issues/105):

To schedule regular maintenance we need to track the total amount of motion on each joint. 

Possible method:

In DexRun.c, 
- new array `joint_odo[NUM_JOINTS]`
- load joint_odo from odometer.txt on startup. e.g. `setDefaults(DefaultMode);`
-  in `int MoveRobot(` and `int moveRobotPID(`
- -  Add abs(joint movement) to joint_odo
- When socket closes `close(connfd)` and program end
- -  Write joint_odo to odometer.txt 

The closing of the socket seems like a good indication that the job is done and no more motion will happen for a while. Each job should run for at least several seconds, if not minutes, and so it shouldn't wear out the SD Card (?)





-------------------------------------------------------------------------------

# [\#104 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/104) `closed`: r 0 #measured_angles not correctly sign extended.
**Labels**: `Firmware`, `bug`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-09-14 17:51](https://github.com/HaddingtonDynamics/Dexter/issues/104):

The values coming out of the FPGA are 18 bit and must be sign extended to correctly report negative angles. Somehow this was missed in testing.   Also, the joint cal slope and home offset were not being applied as it is in getNormalizedInput. Using that routine here standardizes the values.

Fixed in:
https://github.com/HaddingtonDynamics/Dexter/commit/a2ac038300f5d5018e4436b79b916d0165b01537





-------------------------------------------------------------------------------

# [\#103 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/103) `closed`: r 0 #StepAngles returns wrong values for Joint 4 and 5
**Labels**: `Firmware`, `bug`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-09-14 17:06](https://github.com/HaddingtonDynamics/Dexter/issues/103):

For `r 0 #StepAngles` 
https://github.com/HaddingtonDynamics/Dexter/wiki/read-from-robot#keywords

The values returned for Joint 4 and Joint 5 have been "entangled" and actually just reported Motor 4 and Motor 5. 

For Joint 4: ANGLE_STEPS is just MOTOR 4, not joint 4. It interacts with motors 3 and 5 to move the joint. We need to average motor 4 and motor 5, then remove the effect of joint 3. Joint 3 changes the diff by an amount equal to it's stepped position, divided by the different in gearing between joints 3 and 4. Removing that amount gives us the correct position of Joint 4

For Joint 5: ROT_STEPS is just MOTOR 5, not joint 5. It interacts with motor 4 to move the joint. We need to take the difference between motor 4 and motor 5 divided by 2. Joint 3 has no effect, as it changes both diff gears the same, and Joint 5 only reacts to the difference.

Corrected in
https://github.com/HaddingtonDynamics/Dexter/commit/d0b62e74d3b099607d012ec9ac9074febdb3f59d






-------------------------------------------------------------------------------

# [\#102 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/102) `closed`: "Error reading lock file /filename/ Not enough data read"

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-09-10 18:46](https://github.com/HaddingtonDynamics/Dexter/issues/102):

If you try to edit a file after SSHing into Dexter and running `nano <filename>` then what's happened is that the file was previously open for editing, with changes, and Dexters power was cut or the SSH session was disconnected or a new terminal window was accidentally opened. The nano editor (and vim) will leave a backup <filename>.swp file which contains a copy of the edited file. However, it doesn't do a good job of recovering that file for you automatically, instead providing this confusing error message. 

This is especially evident if you forget that Ctrl+S is NOT how you save a file from nano. In Linux, Ctrl+S opens a new terminal window, leaving the old terminal session stopped in the background. So if you are in nano, editing a file, and press Ctrl+S, the nano editor will "disappear" and you will find yourself at a command prompt again wondering what happened. 

If Linux is your friend, you know to type `jobs` to see all the suspended sessions, and then `fg #` where # is the number of the suspended job (probably 1 so `fg 1`) and you are back in nano editing without a problem. But if you don't realize what happened, and you open the file with nano again, you will get this message. If you then disconnect, that nano session in the background will be stopped, but with a .swp file created. 

To resolve the issue, delete any swp files. 
`rm .*swp`
and answer 'y' to each prompt. 

See also:
https://askubuntu.com/questions/939527/getting-error-while-opening-etc-profile-error-reading-lock-file-etc-profile





-------------------------------------------------------------------------------

# [\#101 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/101) `closed`: Dexter shakes on power up if startup scripts are run twice.
**Labels**: `Documentation`, `Firmware`, `Jobware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-09-10 18:34](https://github.com/HaddingtonDynamics/Dexter/issues/101):

Because of confusion with the build team, a robot left the factory with a beta version of the sd card image which had the startup scripts running twice: Once in the RunDexRun file (as per the old way of running jobs on startup) and again in the autoexec.jobs file (which is the new way of running jobs on startup). The second time it ran, the commands caused the robot to shake because the job assumes the robot is in open loop mode. Other than removing the confusion with the build team, perhaps we should change the job so it goes into open loop at the start.




-------------------------------------------------------------------------------

# [\#100 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/100) `closed`: `S 51` does not work as `S LinkLengths`. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-09-03 18:24](https://github.com/HaddingtonDynamics/Dexter/issues/100):

Need to update the code to allow the number to trigger it as well, like `S RunFile` will also work as `S 30`. All the other SetParameter values work because they are set by looking up the number in a table of names, but if you give it a number, it just takes that as if it was the result of that looking. 

Just need to add ` || !strcmp("51",p1)` to the `else if(!strcmp("LinkLengths",p1)){` line in DexRun.c

Watch out for this in adding `ServoSetX` support as well, unless that ends up replacing "ServoSet" on Branch XL-430-Support at:
https://github.com/HaddingtonDynamics/Dexter/blob/XL-430-Support/Firmware/DexRun.c#L5558





-------------------------------------------------------------------------------

# [\#99 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/99) `open`: Create read from robot command for kinematics
**Labels**: `Firmware`, `enhancement`


#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) opened issue at [2020-08-29 20:37](https://github.com/HaddingtonDynamics/Dexter/issues/99):

Something like:
```
'r #J_ANGLES_TO_XYZ 0 36000 0 0 0;'
```
or
```
'r #XYZ_TO_J_ANGLES 0 400000 300000 0 0 -1 1 1 1;'
```

This would allow non-DDE users to do kinematics calculations without actually moving the robot.






-------------------------------------------------------------------------------

# [\#98 PR](https://github.com/HaddingtonDynamics/Dexter/pull/98) `open`: Support Dynamixel XC430 on Tool Interface

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-08-12 22:48](https://github.com/HaddingtonDynamics/Dexter/pull/98):

Address Issue #94  See the issue for extensive additional documentation. 

Line 5607, minor change to keep a 'z' oplet without any parameter from crashing DexRun. Sleep is important to give servos time to reboot during setup.

Removed mention of master / slave.




-------------------------------------------------------------------------------

# [\#97 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/97) `open`: Add ROS support to Dexter
**Labels**: `DDE`, `communication`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-07-30 01:08](https://github.com/HaddingtonDynamics/Dexter/issues/97):

## Desired ROS messages:

Units:
https://ros.org/reps/rep-0103.html


### Bidirectional

http://docs.ros.org/api/sensor_msgs/html/msg/JointState.html
- std_msgs/Header header
- - uint32 seq # sequence ID: consecutively increasing ID
- - time stamp
- - - secs # * stamp.sec: seconds (stamp_secs) since epoch (in Python the variable is called 'secs')
- - - nanosecs # * stamp.nsec: nanoseconds since stamp_secs (in Python the variable is called 'nsecs')
- - string frame_id # ???
- string[] name # name of each joint
- float64[] position # radians
- float64[] velocity # radians / second. Optional when sent to robot, if included, set's max speed
- float64[] effort # newton-meters.  Ignored when sent to robot?

### From host to Robot:

http://docs.ros.org/melodic/api/geometry_msgs/html/msg/Pose.html 
- Point position in meters
- - float64 x
- - float64 y
- - float64 z
- Quaternion orientation (orientation)
- - float64 x
- - float64 y
- - float64 z
- - float64 w

Processing the quaternion requires pretty extensive calculation, which is currently only supported in DDE. We might be able to extract that, but it's not "lightweight". So this message requires that we stick with DDE via the Job Engine on Dexter. 

http://wiki.ros.org/joint_trajectory_controller (not sure if this is part of the "action" system which we perhaps don't want?)
http://docs.ros.org/melodic/api/trajectory_msgs/html/msg/JointTrajectory.html
- std_msgs/Header header
- string[] joint_names
and then a set of way-points:
http://docs.ros.org/melodic/api/trajectory_msgs/html/msg/JointTrajectoryPoint.html
- float64[] positions. radians
- float64[] velocities. radians / second.
- float64[] accelerations. radians / second / second
- float64[] effort. newton-meters
- duration time_from_start

This is unusual because we would need to change velocity and acceleration to meet the time stamps for each position. Again, this seems pretty complex, and something that needs doing in DDE / Job Engine. Apparently you don't send all the items. You might accept the set of (Position, and time) and of (Position, Velocity, and Accelerations) and whatever is missing is up to the robot; e.g. the time stamp can be ignored.

### From the robot back to host:

http://wiki.ros.org/xacro format to convey URDF (robot desciption data) data via ROS PARAM? 
The point here is to allow the URDF to be updated with the actual lengths from the robot.

ROS publisher, publish joint space and measured forces. We get to make this up? Or is there a standard?
One topic for 
- All joints commanded angles
- All joints current angles
- All joints calculated torque
- Current pose

## Notes

List of sensor messages:
http://wiki.ros.org/sensor_msgs?distro=kinetic

As far as I can find, there is no version of Pose which includes this time constraint, and no way to move all joints without the time constraint. How strange! I had really expected that ROS would be doing lower level control, and have a more flexible set of messages. I probably just don't understand it at this point. Edit: Yep, I found the Joint State messages:
http://docs.ros.org/api/sensor_msgs/html/msg/JointState.html

We could just start the ROS Job Engine job every time the robot starts like we do with PHUI, but this would mean the robot would then be a ROS only configured robot, rather than every robot being ready to do ROS if it gets a ROS message. 

To ensure that every Dexter understands ROS if contacted on the main port (ROS "master" port is 11311), we should use the node server just like we do for ModBus or Scratch or the web Job Engine and chat interface. Then, once we get a ROS request, we can start a job and communicate with it via the child process stdin / stdout as we already do for the browser Job Engine interface. Jobs take a second to start, so we will need to receive a "get ready" message which starts the ROS job, and then pass on ROS messages to that job. TODO: This desperately needs to be documented. @cfry 

ROS "action" is different more complex and harder. "move to position by this time" Robot sends back status as it moves, then sends "ok, I'm there". This support is not desired at this time.



#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-01 00:36](https://github.com/HaddingtonDynamics/Dexter/issues/97#issuecomment-667438905):

Sumo contributed the following node.js process, which uses the source code of DDE to implement communications with the robot. This allows DDE to manage the creation of the oplets and waiting for, and decoding, the status response. The repo includes all the files needed, copied from DDE, but the following file (and the config file in the same folder) is the heart of the application. 
https://github.com/schaikunsaeng/DexterRos/blob/master/ros_control_loop/ros_control_loop.js

Note that this implements the 
http://docs.ros.org/api/sensor_msgs/html/msg/JointState.html
message as a subscription to get new joint angle sets, and advertises the same to publish current joint angle positions. 

This also shows an interesting method for accessing sections of DDE without loading all of it. In this case, just the core job functionality is used. I see no reason why this can't be expanded to load the Math and Kin libraries into the node web server for Pose kin and trajectory spline calculations. We can get that working via DDE GUI on the PC, (assuming some way to receive the same message data) and then move that to the job engine at a minimum, for launch from the node server, or perhaps into the node server directly.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-02 16:46](https://github.com/HaddingtonDynamics/Dexter/issues/97#issuecomment-667697296):

### Basic Setup

It appears the ROS Melodic can not be installed on Ubuntu 16.04. It requires 18 and up. Currently, Dexter can not be advanced beyond Xenial / 16.04 See #25 for more on how Dexter's OS is upgraded. The latest ROS version which can be applied to 16.04 is Lunar but that is EOL. Kinetic also supports 16.04 and is supported until April of 2021; about 9 months.

It's our understanding that as long as the message doesn't change, different versions of ROS1 can be used. E.g. a ROS Melodic running on a PC should be able to work with ROS Kinetic on the Robot.

In any case, actually installing and running ROS on the robot is probably of limited value. The FPGA is a stunningly powerful processor, but the dual core ARM 7 processors running the OS are not terribly powerful (about the same as a good tablet or cell phone) and so ROS's higher end processing probably isn't useful on the arm. Also, supporting Dexter with native ROS would require several steps:
1. Learn ROS (which is not our core environment)
2. Write an extension to ROS in C which replaces DexRun.c (or extend DexRun to add in ROS messaging; unlikely given it's complexity)
3. Switch the robot from supporting multiple interfaces to supporting only ROS (assuming a separate ROS only firmware) for those clients which want ROS.

Another possibility is:
https://www.npmjs.com/package/roslib
which is used extensively in the browser environment for ROS but is also available as a node package. Documentation seems very biased towards the browser side with very little for it's use in node. This example looks pretty good:
https://github.com/RobotWebTools/roslibjs/blob/develop/examples/node_simple.js
I'm concerned that this supports only websocket connections and I think ROS normally uses raw sockets?

### rosnodejs

Instead, we can implement a lite weight ROS communications interface on the robot via the rosnodejs NPM package:
https://www.npmjs.com/package/rosnodejs
http://wiki.ros.org/rosnodejs
https://roscon.ros.org/2017/presentations/ROSCon%202017%20rosnodejs.pdf
and then do the work to support desired messages on the robot side via Javascript / DDE / Job Engine. 

There is no requirement listed on the NPM package for ROS to be installed, but on the ROS wiki page, it indicates that ROS must be installed and that only Kinetic is supported. It would be nice to NOT require ROS on the robot in order to be as lite as possible. Luckily, some nerd ask this very question last year:
https://github.com/RethinkRobotics-opensource/rosnodejs/issues/131
and the answer came back:

> Yes, you can, if you:
> - use the onTheFly option (see here), and
> - you have the message definition files of the message types you want to use in your ROS_PACKAGE_PATH (path pointed to by that env variable). 

It looks like you also need to have an environment variable defined for CMAKE_PREFIX_PATH. On the standard install of Kinetic, 
ROS_PACKAGE_PATH="/opt/ros/kinetic/share"
CMAKE_PREFIX_PATH="/opt/ros/kinetic"
To emulate those as close as possible, a ros folder is added under /srv/samba/share, and a "share" folder under that. Those can be added permanently[^](https://help.ubuntu.com/community/EnvironmentVariables#System-wide_environment_variables) with:
````
echo export ROS_PACKAGE_PATH=/srv/samba/share/www/ros/share/>>/etc/environment 
echo export CMAKE_PREFIX_PATH=/srv/samba/share/www/ros/>>/etc/environment 
````
Wherever they point, there needs to be a set of folders under the share folder with message package.xml and msg folder with the .msg files. Something like you find from /opt/ros/kinetic/share/ in a ROS installation. e.g. the std_msgs folder. But watch out for depends which must also be included. e.g. the package.xml for std_msgs lists:
````
<build_depend>message_generation</build_depend>
<run_depend>message_runtime</run_depend>
````

so the message_generation and message_runtime folders must also be included. To support std_msgs and sensor_msgs, I ended up copying in 
- geometry_msgs
- message_generation
- message_runtime
- sensor_msgs
- std_msgs

This allows messages with all the standard string, int32, etc... types from std_msgs, as well as JointState (from sensor_msgs), and Accel, Pose, Quaternion, and others from geometry_msgs. It does not support logging, which seems to have a massive list of dependencies. Not sure what to do about that. Having a light www.zip file that can be dropped into customers robots seems like a good idea.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-11 22:55](https://github.com/HaddingtonDynamics/Dexter/issues/97#issuecomment-672337453):

## Configuration

To work on the ROS network, a few things must be explained to the robot. e.g. where the ROS "Master" (I will call it the "Server" instead) is, and (I think) where the Parameter Server is. Other environmental settings are listed here:
http://wiki.ros.org/ROS/EnvironmentVariables


### ROS Server
To set this, on the robot:
`export ROS_MASTER_URI=http://$1:11311;`
or add that to /etc/environment

### Hostname issues

As per the rosnodejs authors, getting messages to actually pass back and forth involves "editing your /etc/hosts file as well, because ROS is really picky about the way machines are named".

On the PC, I had to add `192.168.1.142 dex-197121` to the /etc/hosts file were the IP address is that of Dexter and the dex-197121 is the name in /etc/hostname which was put there to support #83 . This /might/ not be necessary on other Dexters if that hasn't been set?

Also had to do the same to the /etc/hosts file on Dexter to get it to be able to receive messages. Not only adding the entry for Dexter, but also for the PC. Otherwise, when I sent a message from the PC to Dexter, I would get `[WARN] [1597208618.701] (ros.rosnodejs): Error requesting topic on /chatter: Error: getaddrinfo ENOTFOUND nameofpc nameofpc:40861, undefined` and the only way around that seems to be to put the pc's ip address and hostname into the robots /etc/hostname file. Which is a hack at best. 

Something will need to be done about this. 

### ROS_HOSTNAME=$IP
One way of avoiding the issue is to set the ROS_HOSTNAME environmental variable on both the PC and the robot to the local IP address. Then when a message is sent, it will give that "hostname" as the source and the other end gets the actual IP address for response instead. Many thanks to CFritz for this script, from
https://github.com/RethinkRobotics-opensource/rosnodejs/issues/157#issuecomment-672346984

### `setserver.sh`
````bash
TARGET_IP=$1;
IP=`ip route get $TARGET_IP | head -n 1 | sed "s/.*src \(\S*\) .*/\1/"`;
echo -e "${GREEN}using $1 ($TARGET_IP) via $IP${NORMAL}";
export ROS_MASTER_URI=http://$1:11311;
export ROS_HOSTNAME=$IP;
export ROS_IP=$IP
````
which has been added to the /srv/samba/share/www/ros folder as setserver.sh and `chmod +x setserver.sh`. This can be called on the robot from /srv/samba/share via `. www/ros/setserver.sh server-ip` where the server-ip is replaced with the servers ip. This sets up the URI of the server so the robot can find it, and sets the ROS_HOSTNAME to whatever IP address is being used to route messages to the server. At that point, the ROS configuration is done on the robot side.

Some method for triggering a connection attempt by the node server must be added. I like the idea of a ROS config web page served from Dexter. Perhaps it could also update and run this script, or set the environmental variables itself, and then trigger the node server to connect to the ROS server and show status.

On the ROS server, or any other node which will publish messages to the robot, the hostname must be set to the local IP address, or to a hostname that the robot can resolve to an IP via DNS or some other method. If this isn't done, the robot won't be able to ack messages it receives.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-11 22:55](https://github.com/HaddingtonDynamics/Dexter/issues/97#issuecomment-672337530):

At this point, the following test program is working:
````js
const rosnodejs = require('rosnodejs');
//rosnodejs.loadAllPackages(); NO! Not for onTheFly / Kinetic and up.

rosnodejs.initNode('Dexter', { onTheFly: true
  //,rosMasterUri: `http://192.168.0.134:11311` 
  //not needed if set in environmental variable via www/ros/setserver.sh script
  }).then(() => {
    console.log("Initialized")
    const nh = rosnodejs.nh;
    const stdMsgs = rosnodejs.require('std_msgs');
    const StringMsg = stdMsgs.msg.String;
    const subChatter = nh.subscribe('/chatter', StringMsg, (msg) => { 
      console.log("recvd:"+JSON.stringify(msg)+".") 
      });
    //rostopic pub -1 /chatter std_msgs/String  -- "hello3"
    const pubChatter = nh.advertise('/chatter', StringMsg);
    pubChatter.on('connection', () => {
      console.log("chat connected");
      pubChatter.publish({data: "hi2\n"});
      });
    //pub.publish({data: "hi1\n"}); //this doesn't work

    const SensorMsgs = rosnodejs.require('sensor_msgs');
    console.log("joints:"+JSON.stringify(SensorMsgs.msg))
    const subJointState = nh.subscribe('/joint_states', 'sensor_msgs/JointState', (msg) => { 
      console.log("recvd:"+JSON.stringify(msg)+".") 
      });
//rostopic pub /joint_states sensor_msgs/JointState '{header: {seq: 0, stamp: {secs: 0, nsecs: 0}, frame_id: ""}, name: ["J1", "J2", "J3"], position: [150.0, 0], velocity: [0.0, 0], effort: [0.0, 0]}' --once


    const joints = {header: {seq: 0, stamp: {secs: 0, nsecs: 0}, frame_id:""}
	,name: ["J1","J2","J3","J4","J5","J6","J7"]
	,position: [0,0,0,0,0,0,0]
	,velocity: [0,0,0,0,0,0,0]
	,effort:   [0,0,0,0,0,0,0]
	};
    const pubJointState = nh.advertise('/joint_states', 'sensor_msgs/JointState');
    pubJointState.on('connection', () => {
      console.log("joint connected");
      pubJointState.publish(joints);
      });

//rostopic pub /test geometry_msgs/Pose '{position: {"x":0.1,"y":0.2,"z":0.3}, orientation: {"w":1, "x":0, "y":0, "z":0}}' --once

    const subPose = nh.subscribe('/pose', 'geometry_msgs/Pose', (msg) => { 
      console.log("recvd:"+JSON.stringify(msg)+".") 
      });

    } //initnode callback
  );

````

### Custom Message

https://github.com/RethinkRobotics-opensource/rosnodejs#generating-messages
> When generating on the fly, messages can not be required until the node has initialized.
```js
const rosnodejs = require('rosnodejs');
await rosnodejs.initNode('my_node', { onTheFly: true })
const stdMsgs = rosnodejs.require('std_msgs');
````

Hopefully that won't be an issue. I believe that using the node server, Dexter will /always/ be ready to receive messages from a ROS "host" (moving away from "master" as a term) and the advertised topics should be accessible immediately as well. If we need to use the job engine, then some means of starting that job will be required (init message) or the robot can be configured to start that ROS job on boot. (again, that would limit the robot to being /only/ ROS). 

Now to figure out the ROS message definition files...

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-15 23:18](https://github.com/HaddingtonDynamics/Dexter/issues/97#issuecomment-674456823):

## URDF

Spec at: https://wiki.ros.org/urdf/XML most of that is very simple, but the [physical properties](http://wiki.ros.org/urdf/Tutorials/Adding%20Physical%20and%20Collision%20Properties%20to%20a%20URDF%20Model#Physical_Properties) are quite confusing. 

This video provided an excellent overview of URDF files, their capabilities and limitations:
https://www.youtube.com/watch?v=g9WHxOpAUns

Testing a URDF file: `check-urdf <filename>`. Visualize a URDF with `rviz`. 

You need the Display Model add on, but the parameter containing the contents of the urdf file must be set. By default, the parameter is called /robot_description. To load it from a file: `rosparam set /robot_description --textfile <filename>` We should be able to do the same thing from the node server on Dexter when it's configured / the ROS server is setup. 

To move joints around, you need the joint_state_publisher but that has been broken off into a separate "gui" which isn't installed by default, so: `sudo apt install ros-kinetic-joint-state-publisher-gui`
and there are a number of components which must be launched, so it's easy to just re-use the urdf_tutorial launch file and substitute your own file: `roslaunch urdf_tutorial display.launch model:=<filename>`

Here is the current Dexter.urdf file for 5 joints:
````xml
<?xml version="1.0"?>

<robot name="Dexter" xmlns:xacro="http://ros.org/wiki/xacro">
<xacro:property name="cadpath" value=""/>
<!-- To view with CAD files, download the "LowRes*.stl" files from 
https://drive.google.com/drive/folders/1JNs-h3x_sM75Rum5aerc5YCDE0ybJRp3
then edit the above line to point to the location of those files, e.g.:
<xacro:property name="cadpath" value="file:///home/jamesn/Documents/"/>  -->

<xacro:property name="LINK1" value="0.245252"/>
<xacro:property name="LINK2" value="0.339092"/>
<xacro:property name="LINK3" value="0.307500"/>
<xacro:property name="LINK4" value="0.059500"/>
<xacro:property name="LINK5" value="0.082440"/>

<xacro:property name="L2Xoff" value="-0.056"/>
<xacro:property name="L2Zadd" value="0.15"/> //L2 motor counterbalance
<xacro:property name="L2Xsize" value="0.095"/> //Approx thick
<xacro:property name="L2Ysize" value="0.11"/> //Approx width

<xacro:property name="L3Xoff" value="-0.066"/>
<xacro:property name="L3Xsize" value="0.05"/> //Approx thick
<xacro:property name="L3Ysize" value="0.07"/> //Approx width

<xacro:property name="L4Xoff" value="-0.020"/>
<xacro:property name="L5Zoff" value="-0.021"/>

  <material name="onyx">
    <color rgba="0.1 0.1 0.1 1"/>
  </material>

  <link name="base_link">
    <visual>
<xacro:if value="${cadpath==''}">
      <geometry>
        <cylinder length="${LINK1-0.025}" radius="0.05"/>
      </geometry>
      <origin rpy="0 0 0" xyz="0 0 ${(LINK1-0.025)/2}"/> 
</xacro:if>
<xacro:unless value="${cadpath==''}">
      <geometry>
        <mesh filename="${cadpath}LowRes_DexterHDIKinematic_Link1_Bottom.stl" scale="0.001 0.001 0.001"/> 
      </geometry>
      <origin rpy="1.5708 0 -1.5708" xyz="0 0 0"/>
</xacro:unless>
      <material name="onyx"/>
    </visual>
    <collision>
      <geometry>
        <cylinder length="${LINK1-0.025}" radius="0.05"/>
      </geometry>
      <origin rpy="0 0 0" xyz="0 0 ${(LINK1-0.025)/2}"/> 
    </collision>
  </link>

  <link name="link1">
    <visual>
<xacro:if value="${cadpath==''}">
      <geometry>
        <box size="0.1 0.05 0.05"/>
      </geometry>
      <origin rpy="0 0 0" xyz="-0.025 0 0"/>
</xacro:if>
<xacro:unless value="${cadpath==''}">
      <geometry>
        <mesh filename="${cadpath}LowRes_DexterHDIKinematic_Link1_Top.stl" scale="0.001 0.001 0.001"/> 
      </geometry>
      <origin rpy="1.5708 0 -1.5708" xyz="0 0 -0.0375"/>
</xacro:unless>
      <material name="onyx"/>
    </visual>
    <collision>
      <geometry>
        <box size="0.1 0.05 0.05"/>
      </geometry>
      <origin rpy="0 0 0" xyz="-0.025 0 0"/>
    </collision>
  </link>

  <link name="link2">
    <visual>
<xacro:if value="${cadpath==''}">
      <geometry>
        <box size="${L2Xsize} ${L2Ysize} ${LINK2+L2Ysize+L2Zadd}"/> //add Ysize to account for joint curve
      </geometry>
      <origin rpy="0 0 0" xyz="${L2Xoff-L2Xsize/2} 0 ${(LINK2+L2Zadd+L2Ysize)/2-L2Zadd-L2Ysize/2}"/>
</xacro:if>
<xacro:unless value="${cadpath==''}">
      <geometry>
        <mesh filename="${cadpath}LowRes_DexterHDIKinematic_Link2.stl" scale="0.001 0.001 0.001"/> 
      </geometry>
      <origin rpy="1.57079 0 -1.5708" xyz="${L2Xoff} 0 0"/>
</xacro:unless>
      <material name="onyx"/>
    </visual>
    <collision>
      <geometry>
        <box size="${L2Xsize} ${L2Ysize} ${LINK2+L2Ysize+L2Zadd}"/> //add Ysize to account for joint curve
      </geometry>
      <origin rpy="0 0 0" xyz="${L2Xoff-L2Xsize/2} 0 ${(LINK2+L2Zadd+L2Ysize)/2-L2Zadd-L2Ysize/2}"/>
    </collision>
  </link>

  <link name="link3">
    <visual>
<xacro:if value="${cadpath==''}">
      <geometry>
        <box size="${L3Xsize} ${L3Ysize} ${(LINK3+L3Ysize)}"/>
      </geometry>
      <origin rpy="0 0 0" xyz="${L3Xoff+L3Xsize/2} 0 ${(LINK3+L3Ysize)/2-L3Ysize/2}"/>
</xacro:if>
<xacro:unless value="${cadpath==''}">
      <geometry>
        <mesh filename="${cadpath}LowRes_DexterHDIKinematic_Link3.stl" scale="0.001 0.001 0.001"/> 
      </geometry>
      <origin rpy="1.57079 0 -1.5708" xyz="${L3Xoff} 0 0"/>
</xacro:unless>
      <material name="onyx"/>
    </visual>
    <collision>
      <geometry>
        <box size="${L3Xsize} ${L3Ysize} ${(LINK3+L3Ysize)}"/>
      </geometry>
      <origin rpy="0 0 0" xyz="${L3Xoff+L3Xsize/2} 0 ${(LINK3+L3Ysize)/2-L3Ysize/2}"/>
    </collision>
  </link>

  <link name="link4">
    <visual>
<xacro:if value="${cadpath==''}">
      <geometry>
        <cylinder length="0.05" radius="0.027"/> 
      </geometry>
      <origin rpy="0 0 0" xyz="0 0 0.015"/>
</xacro:if>
<xacro:unless value="${cadpath==''}">
      <geometry>
        <mesh filename="${cadpath}LowRes_DexterHDIKinematic_Link4.stl" scale="0.001 0.001 0.001"/> 
      </geometry>
      <origin rpy="1.57079 0 -1.5708" xyz="${L4Xoff} 0 0"/>
</xacro:unless>
      <material name="onyx"/>
    </visual>
    <collision>
      <geometry>
        <cylinder length="0.05" radius="0.027"/> 
      </geometry>
      <origin rpy="0 0 0" xyz="0 0 0.015"/>
    </collision>
  </link>

  <link name="link5">
    <visual>
<xacro:if value="${cadpath==''}">
      <geometry>
        <cylinder length="${LINK5}" radius="0.027"/> 
      </geometry>
      <origin rpy="1.57079 0 0" xyz="0 -0.013 0"/>
</xacro:if>
<xacro:unless value="${cadpath==''}">
      <geometry>
        <mesh filename="${cadpath}LowRes_DexterHDIKinematic_Link5.stl" scale="0.001 0.001 0.001"/> 
      </geometry>
      <origin rpy="1.57079 0 -1.5708" xyz="0 0 ${L5Zoff}"/>
</xacro:unless>
      <material name="onyx"/>
    </visual>
    <collision>
      <geometry>
        <cylinder length="${LINK5}" radius="0.027"/> 
      </geometry>
      <origin rpy="1.57079 0 0" xyz="0 -0.013 0"/>
    </collision>
  </link>

<!--S, LinkLengths, 82551, 50801, 330201, 320676, 228600 -->
  <joint name="J1" type="revolute">
     <parent link="base_link"/>
     <child link="link1"/>
     <axis xyz="0 0 1"/>
     <origin xyz="0 0 0.228600"/><!-- z=L1 -->
     <dynamics damping="0.0" friction="0.0"/>
     <limit effort="30" velocity="1.0" lower="-3.316" upper="3.316" /> <!-- bounds in radians -->
   </joint>

  <joint name="J2" type="revolute">
     <parent link="link1"/>
     <child link="link2"/>
     <axis xyz="1 0 0"/>
     <origin xyz="0 0 0"/><!-- y=L1cl to back of j2 drive Z=0 because already at L1-->
     <limit effort="30" velocity="1.0" lower="-1.745" upper="1.745" /> <!-- bounds in radians -->
   </joint>

  <joint name="J3" type="revolute">
     <parent link="link2"/>
     <child link="link3"/>
     <axis xyz="1 0 0"/>
     <origin xyz="0 0 ${LINK2}"/><!-- y=half way from back of j3 drive to L1cl z=L2  -->
     <limit effort="30" velocity="1.0" lower="-2.8797" upper="2.8797" /> <!-- bounds in radians -->
   </joint>

  <joint name="J4" type="revolute">
     <parent link="link3"/>
     <child link="link4"/>
     <axis xyz="1 0 0"/>
     <origin xyz="0 0 ${LINK3}"/><!-- y=rest of the way from back of j3 drive to L1cl z=L3 -->
     <limit effort="30" velocity="1.0" lower="-2.1816" upper="2.1816" /> <!-- bounds in radians -->
   </joint>

  <joint name="J5" type="revolute">
     <parent link="link4"/>
     <child link="link5"/>
     <axis xyz="0 0 1"/>
     <origin xyz="0 0 ${LINK4}"/><!-- z=L4 -->
     <limit effort="30" velocity="1.0" lower="-3.3161" upper="3.3161" /> <!-- bounds in radians -->
   </joint>

</robot>


````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-17 18:49](https://github.com/HaddingtonDynamics/Dexter/issues/97#issuecomment-675050701):

### Services

http://wiki.ros.org/ROS/Tutorials/UnderstandingServicesParams

Perhaps an /init or /reset service should be provided by the robot to start the ROS job engine and get it ready for communications? This would avoid any issues with slow response on the first ROS message send to the robot as it starts the job engine.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-19 02:09](https://github.com/HaddingtonDynamics/Dexter/issues/97#issuecomment-675809917):

### ROS.dde

A job engine job to receive and process ROS messages in JSON format has been written by @JamesWigglesworth 
`/srv/samba/share/dde_apps/ROS.dde`
````js
//Written by James Wigglesworth
//Started: 8_18_20
//Modified: 8_18_20

Dexter.LINK1 = 0.2352
Dexter.LINK2 = 0.339092
Dexter.LINK3 = 0.3075
Dexter.LINK4 = 0.0595
Dexter.LINK5 = 0.08244

new Job({
    name: "ROS",
    inter_do_item_dur: 0,
    show_instructions: false,
    keep_history: false,
    user_data: {
    	ws_message: false,
        xyz: [0, 0.5, 0.4],
        stiffnesses: [12.895, 12.895, 1.2568, 0.1503, 0.1503],
        StepAngles: "[0, 0, 0, 0, 0]",
        step_angles: [0, 0, 0, 0, 0],
        position_prev: [0, 0, 0, 0, 0, 0, 0],
      	time_prev: Date.now() / 1000 / _ns
    },
    do_list: [
    	function(){
        	out("ROS.dde has been started")
        },
        Robot.loop(true, function(){
        	let CMD = []
        	if(this.user_data.ws_message){
            	let message
                try{
                	message = JSON.parse(this.user_data.ws_message)
                }catch(err){
                	out("ws_message is not JSON parsable:")
                    console.log(message)
                    this.user_data.ws_message = false
                    return
                }
                
                if(typeof (message) === "object"){
                	CMD.push(ROS_to_DDE(message))
                }
                
            	this.user_data.ws_message = false
            }else{
            	CMD.push(Dexter.get_robot_status())
                CMD.push(function(){
    				let StepAngles = Vector.multiply(JSON.parse(this.user_data.StepAngles), _arcsec)
    				this.user_data.step_angles = StepAngles
				})
            }
            
            send_ROS_message(DDE_to_ROS(this))
            
            return CMD
        })
    ]
})

function send_ROS_message(string){
	//out(string) //TODO: slow this down. 
}

function ROS_to_DDE(message){
	let position = message.position
    let velocity = message.velocity
    let effort = message.effort
    let pose = message.pose
    let CMD = []
    
    if(position && !velocity && !effort){
    	CMD.push(Dexter.move_all_joints(Vector.multiply(position, _rad)))
    }else if(!position && velocity && !effort){
    	//i_moves go here
    }else if(!position && !velocity && effort){
    	//i_move with torque feedback goes here
    }else if(pose){
    	let quaternion = [1, 0, 0, 0]
        let xyz = [0, 0.4, 0.4]
        let DCM = Vector.quaternion_to_DCM(quaternion)
        let dir = Vector.multiply(-1, Vector.pull(DCM, [0, 2], 2))
        out("dir: " + dir)
        CMD.push(Dexter.pid_move_to(xyz, dir))
    }
    
	return CMD   
}

function DDE_to_ROS(job){
	let rs = job.robot.robot_status
    let position = [
    	rs[Dexter.J1_MEASURED_ANGLE],
        rs[Dexter.J2_MEASURED_ANGLE],
        rs[Dexter.J3_MEASURED_ANGLE],
        rs[Dexter.J4_MEASURED_ANGLE],
        rs[Dexter.J5_MEASURED_ANGLE],
        rs[Dexter.J6_MEASURED_ANGLE],
        rs[Dexter.J7_MEASURED_ANGLE]
    ]
    let position_rad = Vector.multiply(1 / _rad, position)
    
    let time = rs[Dexter.START_TIME] + rs[Dexter.STOP_TIME] / 1000000
    //out(time, "blue", true)
    let time_nano_secs = time / _ns
    //out(time_nano_secs, "blue", true)
    let position_prev = job.user_data.position_prev
    let time_prev = job.user_data.time_prev
    let velocity = Vector.divide(Vector.subtract(position_rad, position_prev), time_nano_secs - time_prev)
    
    let torque = [...compute_torque(position, job.user_data.step_angles, job.user_data.stiffnesses), rs[Dexter.J6_MEASURED_TORQUE], rs[Dexter.J7_MEASURED_TORQUE]]
    
    let message = {
		header: {
    		seq: 0,
        	stamp: {
        		secs: time,
            	nsecs: time_nano_secs
        	},
        	frame_id: ""
    	},
		name: ["J1", "J2", "J3", "J4", "J5", "J6", "J7"],
		position: position_rad,
		velocity: velocity,
		effort: torque
	}
    
    job.user_data.position_prev = position_rad
    job.user_data.time_prev = time_nano_secs
    
    return JSON.stringify(message)
}

function compute_torque(measured_angles, step_angles, stiffnesses, hysterhesis_low = [0, 0, 0, 0, 0], hysterhesis_high = [0, 0, 0, 0, 0]){
	let torques = [0, 0, 0, 0, 0]
    let displacement
    for(let i = 0; i < 5; i++){
    	displacement = measured_angles[i] - step_angles[i]
    	torques[i] = 0
        if(displacement < hysterhesis_low[i]){
    		torques[i] = (measured_angles[i] - step_angles[i] - hysterhesis_low[i]) * stiffnesses[i]
        }else if(displacement > hysterhesis_high[i]){
        	torques[i] = (measured_angles[i] - step_angles[i] - hysterhesis_high[i]) * stiffnesses[i]
        }
    }
    return torques
}





````

For now, it can be tested from the debug console in chrome after starting the job via the browser job engine interface and then executing:
`web_socket.send('{"job_name_with_extension":"ROS.dde","ws_message":{"header":{"seq":0,"stamp":{"secs":0,"nsecs":0},"frame_id":""},"name":["J1","J2","J3","J4","J5","J6","J7"],"position":[0,0,1,0,0,0,0]}}')`


-------------------------------------------------------------------------------

# [\#96 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/96) `open`: User design speed curves for each joint on FPGA
**Labels**: `Gateware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-07-13 23:50](https://github.com/HaddingtonDynamics/Dexter/issues/96):

Currently we need to break up a move to straight into small movements and each of those has a trapezoidal speed profile. 

If we wanted true control of the speed and position while moving in a straight line, we will need to be able to pass in complex speed curves at a very high resolution. This could be implemented as a series of trapezoidal movements with different end speeds or as a lookup table of speeds that is interpolated during the move by the FPGA.

 

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) commented at [2020-09-14 05:47](https://github.com/HaddingtonDynamics/Dexter/issues/96#issuecomment-691825883):

The first stab of this has been done in [this commit of DexRun.c](https://github.com/HaddingtonDynamics/Dexter/blob/Stable_Conedrive_Move_To_Straight/Firmware/DexRun.c).

It turns out the functionally has been there for a while in the form of DMA playback.
Originally this was used to do recordings and playback before DDE.
We were able to covert complex positional curves into this format which allows us direct control of the stepper motors in time.

The first functionality added is an improved move_to_straight.
This uses the ['Cartesian...' set parameters](https://github.com/HaddingtonDynamics/Dexter/wiki/set-parameter-oplet).


Here is the DDE code to run it (only works in DDE versions 2.5.17 and not 3.6.3 but possibly later versions):
````js
new Job({
	name: "Straight_Test",
    do_list: [
    	Dexter.set_parameter("MaxSpeed", 25),
        Dexter.set_parameter("StartSpeed", 0),
        Dexter.move_to([-0.1, 0.5, 0.3], [0, 0, -1], [1, 1, 1]),
        make_ins("F"),
        
        Dexter.set_parameter("CartesianSpeed", Math.round(0.4/_um)),
        Dexter.set_parameter("CartesianAcceleration", Math.round(1/_um)),
        Dexter.set_parameter("AngularSpeed", Math.round(100/_arcsec)),
        make_ins("T", 0.1, 0.5, 0.3, 0, 0, -1, 1, 1, 1),
        
        Dexter.set_parameter("MaxSpeed", 25),
        Dexter.set_parameter("StartSpeed", 0),
        Dexter.move_all_joints([0, 0, 0, 0, 0]),
        make_ins("F")
    ]
})
````

What still needs to be done:
-It takes like a second or two between movements (which is a lot better than 5 minutes)
    -I couldn't figure out how to write directly to the DMA or use the CalTables array and load the table.
     What was able to to do was write everything out to a file then load that file back in and do the normal 'o' oplet.
    -I'm not being efficient with the file size, there are a bunch of zero step data points getting put in there.
     As the file size goes down the computation time will go up so we'll have figure the right balance of this trade off.


-An input into this function is 'max_speed_guess' which is used to calculate the minimum time step that could occur.
 This minimum time step is what I take time samples at (like a frame rate).
 If a joint is moving at exactly the speed of max_speed_guess it will move at 1 motor step per time step.
 If it calculates more than 1 motor step per this time step all of the math breaks.
 Effectively I want this to error and not move if this occurs, but I don't really have a mechanism for this.
 Right now it will actually move until it reaches this max_speed_guess then come to an abrupt and violent stop.
 (max_speed_guess can be set with a the set param of 'AngularSpeed' for now.)


-I don't have a mechanism for letting the user know an xyz was out of bounds (or if a joint was passed boundary either).


-It only works with a direction of [0, 0, -1] for both end points.
 Eventually I'd like to allow different start and end directions and interpolate between them.
 There is an issue for calculating the acceleration curve when the start and end directions are different but the start and end xyz's are the same.


-CartesianStartSpeed and CartesianEndSpeed can only be zero.


-It is not possible to queue multiple 'T' oplets, it only returns the robot status after the robot status is complete.
 This is actually kind of nice because it makes it synchronous by default, instead using the 'F' oplet (empty_instruction_queue)


MoveRobotStraight(), which is what is called by the 'T' oplet, has been replace with a new algorithm.
This algorithm generates the raw step, direction, and duration format that directly controls the motors through the FPGA via the DMA.
This allows maximum smoothness and speed of straight line motion.

New functions:
unsigned int make_bin_string(bool step[], bool dir[], unsigned int time)
void position_curve_to_dma(void time_to_J_angles(float))
position_curve_straight(float t)


position_curve_straight is just the first function to be used for this direct motor control.
It takes an argument of 't' for time in seconds and results in a global variable time_to_J_angles_result being set to a set of joint angles in arcseconds.

A number of different functions can be written in this format including:
-position_curve_playback_recording
-position_curve_circle
-position_curve_polyline
-position_curve_natural_cubic_spline
-position_curve_constant_acceleration 
etc.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-09-14 20:51](https://github.com/HaddingtonDynamics/Dexter/issues/96#issuecomment-692307348):

I'll try to help with writing directly to RAM.

"I'm not being efficient with the file size, there are a bunch of zero step data points getting put in there. As the file size goes down the computation time will go up so we'll have to figure the right balance of this trade off." 

I don't see why the computation should be difficult... just compute based on the minimum time slice as before, and keep the current value rather than immediately writing it out, then compute the next value. If there is no step change, add the two times, keep that (don't write it out) and compute another slice. If there IS a change in the steps, then write out the prior, saved, value, and hold on to the new value as before. That can't take more than a few cycles... On the other hand, with 2 million points, I'm not sure how critical it is to save space, once we get past writing it to a file. Oh... maybe doing all those minimum-time-slice computations which result in no changes is what you were talking about?

On max_speed_guess, is the problem that the guess is sometimes wrong? And you don't know it's wrong until the time slices are overwhelmed and then it's too late. That could be caught now and just don't load the file, but as we move to doing 

Maybe you can vary the width of the time slice and increase or decrease it to make sure that there are enough slices between a step to ensure accurate timing.

Or use the floating point values in the step time computation to put out an exact delay instead of slicing up time into fixed units. 

"...letting the user know an xyz was out of bounds (or if a joint was passed boundary either)." XYZ is just the donut thing, right? And joints out of bounds can also be tracked. Just more work, right? Maybe I can help there.

Queueing (in firmware, no FPGA) and different end and start speeds will all come once we can go direct to RAM.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2020-09-15 03:39](https://github.com/HaddingtonDynamics/Dexter/issues/96#issuecomment-692443342):

"I don't see why the computation should be difficult... just compute based
on the minimum time slice as before, and keep the current value rather than
immediately writing it out, then compute the next value. If there is no
step change, add the two times, keep that (don't write it out) and compute
another slice. If there IS a change in the steps, then write out the prior,
saved, value, and hold on to the new value as before."

Sounds like a good algorithm to me.
Now once we have that, consider generalizing it
a bit, from
"If there is no step change" to
"If the change is below X" where we can decide
how high to set this "low pass filter".
ie maybe sometimes we're willing to trade off
"perfect fidelity" with "something not so perfect
but a heck of a lot less data."
Ie "not so lossy compression".
I'm not sure my above algorithm would do it,
but taking out the little jitters I'd think would
be better than the original, at least for some purposes.


On Mon, Sep 14, 2020 at 4:52 PM JamesNewton <notifications@github.com>
wrote:

> I'll try to help with writing directly to RAM.
>
> "I'm not being efficient with the file size, there are a bunch of zero
> step data points getting put in there. As the file size goes down the
> computation time will go up so we'll have to figure the right balance of
> this trade off."
>
> I don't see why the computation should be difficult... just compute based
> on the minimum time slice as before, and keep the current value rather than
> immediately writing it out, then compute the next value. If there is no
> step change, add the two times, keep that (don't write it out) and compute
> another slice. If there IS a change in the steps, then write out the prior,
> saved, value, and hold on to the new value as before. That can't take more
> than a few cycles... On the other hand, with 2 million points, I'm not sure
> how critical it is to save space, once we get past writing it to a file.
> Oh... maybe doing all those minimum-time-slice computations which result in
> no changes is what you were talking about?
>
> On max_speed_guess, is the problem that the guess is sometimes wrong? And
> you don't know it's wrong until the time slices are overwhelmed and then
> it's too late. That could be caught now and just don't load the file, but
> as we move to doing
>
> Maybe you can vary the width of the time slice and increase or decrease it
> to make sure that there are enough slices between a step to ensure accurate
> timing.
>
> Or use the floating point values in the step time computation to put out
> an exact delay instead of slicing up time into fixed units.
>
> "...letting the user know an xyz was out of bounds (or if a joint was
> passed boundary either)." XYZ is just the donut thing, right? And joints
> out of bounds can also be tracked. Just more work, right? Maybe I can help
> there.
>
> Queueing (in firmware, no FPGA) and different end and start speeds will
> all come once we can go direct to RAM.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/96#issuecomment-692307348>,
> or unsubscribe
> <https://github.com/notifications/unsubscribe-auth/AAJBG7KPGNI6Z43RQ72JQBTSFZ67DANCNFSM4OY7E3WQ>
> .
>


-------------------------------------------------------------------------------

# [\#95 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/95) `open`: Separate deceleration / speed curve in move all joints
**Labels**: `Gateware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-07-13 23:43](https://github.com/HaddingtonDynamics/Dexter/issues/95):

Support deceleration separately from acceleration or generally control the entire speed curve for motion ramping in the FPGA. 




-------------------------------------------------------------------------------

# [\#94 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/94) `open`: Support Dynamixel XC430 on Tool Interface
**Labels**: `Firmware`, `Hardware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-06-30 21:04](https://github.com/HaddingtonDynamics/Dexter/issues/94):

The XL-320s have a limited rotational range which sometimes limits our ability to do things. The XC430 doesn't cost much more and provides higher torque, stronger body, and continuous rotation modes. It is, however, physically larger and so is not a direct replacement. It also has a completely different memory map and more complex operating modes. 

We are looking at the XC-430-W240:
https://emanual.robotis.com/docs/en/dxl/x/xc430-w240/

### r 0 #Servo ID, Addr, Len
There is a new #Servo # Addr Len for the 'r' (read from robot) oplet that lets you query a servo directly and get back the result. I'm hoping it might be helpful for reading back torques really quickly (faster than the monitor mode) or for diagnosing Servo issues. e.g. 
````
r 0 #Servo 1 32 2; Read Max Voltage (currently returning A0 or 160 or 16 volts)
r 0 #Servo 1 34 2; Read Min Voltage (currently returning 3C or 60 or 6 volts)
r 0 #Servo 1 70 1; Read Hardware error (returns 1 which is "Input Voltage Error")
````
Sending an `S RebootServo 1;` does not resolve the error. Sending an `S ServoSet2X 1 34 59;` Set Max Min voltage 0x22 0x3B gets me a packet status error of 0x84 which is "Data Range Error: Data to be written in the corresponding Address is outside the range of the minimum/maximum value"

So it's looking like our days of running the servos at 5 volts when they are spec'd for a min of 6 volts are over. Supporting the XC430's will apparently require another power supply... Not sure why the XL320's were willing to work at 5 volts and the XC430's don't seem to be.

We do, as it happens, have an extra power supply ready to go:
https://workspace.circuitmaker.com/Projects/Details/James-Newton-2/Dexter-Tool-Interface-Servo-Power-Supply
But it's another item on the BOM, it's hard to find a place to mount it, and getting them made is a pain. When I designed it, I looked for anything we could just buy from China, but didn't find anything that met the requirements. The XL320 max voltage is 8.4, but the XC430 will run on up to 14.8, so a more commonly available 12 volt unit like:
http://filecenter.deltaww.com/Products/download/01/0102/datasheet/DS_V36SE12004.pdf
will now work. If you get the "negative logic" version, be sure to short the "ON/OFF" input the ground to get it to work. On the "positive logic" version, you must leave that pin floating. 

Servo Read code: (place in the 'r' handler)
````
}else if (strcmp(token, "#Servo") == 0) { //Read from servo number at addr for length. 
  int servo_start = 0;
  int servo_length = 0;
  unsigned char servo = 0;
  token = strtok(NULL, delimiters); if (token) servo = token[0]-'0'; //which servo? Single digit 1..255
  token = strtok(NULL, delimiters); if (token) servo_start = atoi(token); //starting address, can be zero
  token = strtok(NULL, delimiters); if (token) servo_length = atoi(token); //data length, must be > 0
  printf("Reading servo %d at %d for %d\n", servo, servo_start, servo_length);
  if (servo && servo_length 
  	&& !SendReadPacket((unsigned char *)(sendBuff + sizeof(sendBuffReTyped[0])*7), servo, servo_start, servo_length)
	) { //got a valid reply. Save in sendBuff then convert to ASCII hex in mat_string (can't return binary 'cause strlcpy)
	servo_length += 11; //11 more because of protocal overhead (header, crc, etc...)
	for(i = 0; i < servo_length; i++) sprintf(mat_string+3*i, "%.2X ", sendBuff[i+sizeof(sendBuffReTyped[0])*7]);
	mat_string_length = servo_length * 3; //2 hex digits and a space for each byte
	//printf("Return %d\n", mat_string_length);
  	}
````


Useful instructions:

````
r 0 #Servo 1 32 2; Read Max Voltage
r 0 #Servo 1 34 2; Read Min Voltage
r 0 #Servo 1 70 1; Read Hardware error

````

### S ServoSetX ID Addr Len [Data]
Added a new ServoSetX set parameter which can take several parameters:
- Servo ID: The expected ID number of the servo on the Dynamixel bus
- Address: The address in the header or ram table in the servo
- Data/Length: This can either be a single byte of data (which makes ServoSetX work just like ServoSet) or, if the next parameter is specified, then this is the length of the data string
- Data String: (optional) If specified, this is a string of data. Because 0x00 (nulls), and 0x3B (;) can't pass initial parse, these are esc'd w/ 0x25 (%). And of course, that means the % must be escaped as well. For example: 0x00,0x3B,0x25 would become %00%3B%25 and have a Length parameter of 9 but would end up writing 3 bytes to the servo. Another example: AB%20 would become AB%2520 (the % is replaced with %25) and would have a length of 7 but would actually send 5 bytes.

Internally ServoSet2X and ServoSet are replaced with ServoSetX. 

TODO: Should ServoSet be removed from the code and ServoSetX be renamed to ServoSet.

````
S ServoSet2X 1 32 160; Set Max Max voltage 0x20 0xA0
S ServoSet2X 1 34 59; Set Max Min voltage 0x22 0x3B
````



#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-30 01:44](https://github.com/HaddingtonDynamics/Dexter/issues/94#issuecomment-666029402):

### S RebootServo ID [Type [Slope Offset]]

Change `S RebootServo _id_` to take `S RebootServo _id_ _type_` e.g. `S RebootServo 2 430` which adds a new servo to the list to be monitored with a type of XC430. The monitor has been updated to monitor up to 20 servos, but it only checks one per monitor loop. The loop speed has been increased to once every ~5000us. So if there are only 2 servos, they get checked a bit faster than they did before (was 15000) but if there are 10, the monitor doesn't lock up, it just checks each one every 500us or so. 

Of course, there is currently NO way to get the data collected for any servo address other than 1 or 3 (joints 7 or 6) back from the robot, but that will come. Probably need to expand `r 0 #Servo` to return all monitored servos positions and loads, and `r 0 #Servo _id_` to return the position and load of that servo. 

Currently, @jonfurniss has shown that the Physical User Interface works for recording and playback with the 430's, but there are issues because the units are wrong. If you tell a 320 to move 1, that is 0.29' but a 430, it's 0.08789' 

The plan is use JointsCal and HomeOffset values to correct for those units. The units for JointsCal are a bit confusing. They are a ratio between arcseconds and the amount a joint moves with a single step of the motor; or in the case of servos, a single unit change in the commanded goal. To avoid floating point numbers, they are specified by `S AxisCal` after multiplying the desired fractional value by 3600 * 360 i.e. by arcseconds per revolution. So any value specified is first divided by 3600 * 360 and saved as a floating point. So they are specified in arcseconds, but they are used as a ratio which does not have units. 

In the past, values for Joint 6 or Joint 7 would NOT be changed by the firmware at all. They were just passed through to the servo. This was the way of it for 'a' and 'p' and for `S EERoll` or `S EESpan`

Now the firmware is adding the corresponding element of HomeOffset and then multiplying the value sent by the corresponding element of the JointsCal array. This correction is now in place, but there was no way to set numbers into those correction factors because the `S AxisCal ...` and `S HomeOffset ...` only take 5 parameters. 

RebootServo has been modified to optionally accept JointsCal and HomeOffset values along with the servo type. If the servo type is not specified, JointsCal and HomeOffset are not changed. If only the type is specified, 1 and 0 are assumed for the slope and offset.

````c
case 29:     // ServoReset
	//printf("Servo Reboot %d",a2);
	if (a3) {
		//need to translate 3->5, 1->6, 2->7, 4->8 and so on. ServoAddr(joint) does the opposite. 
		i = NUM_JOINTS + a2 - 1; //4->8, 5->9
		switch (a2) {
			case 1: i = 6; break; //J7, zero indexed
			case 2: i = 7; break; //J8
			case 3: i = 5; break; //J6
			default: break;
			}
		ServoData[a2].ServoType = (enum ServoTypes)a3;
		if (a3>0) { //if the servo type was supplied
			if (0 == a4) {a4=(3600*360);};
			JointsCal[i] = (float)a4 / (3600*360);
			HomeOffset[i] = a5;
			printf("With slope %f offset %d, ", JointsCal[i], HomeOffset[i]);
			}
		printf("Servo %d joint %d set to type %d \n", a2, i+1, a3);
		}
	RebootServo(a2); 
	return 0;
````

And now the 

For example:

**Default Mode** Just powering on the robot, or doing a `S RebootServo 3 320 1296000 0` would add a standard XL-320 expecting 320 units because 1296000 / (3600 * 360) is 1. You could also just do `S RebootServo 3 320`. If you told DexRun to move that servo 1 unit it would tell the servo to move 1 unit which is 0.29' on an XL-320. This is the "default" value, and it is the "guess" taken in the firmware on startup. By default, servo units are just passed through as always. So this new DexRun.c should not change the operation of existing robots.

**Compatibility Mode** But `S RebootServo 3 430 4270909 0` would setup a 430 with a multiplier of 4270909/(3600 * 360) = ~3.295 because if you tell a 320 to move 1, that is 0.29' but a 430, it's 0.08789' (360/4096) and 0.08789 * 3.295 ~= 0.29' see? So DDE LTS says to move joint 6 by 1 unit, and we multiply that by 3.295 and move the 430 by 3 units or 0.254' (which is as close as we can get to 0.29' in 0.08789' steps). Call that "compatibility mode" 

**XL-430 Mode** Then if you want better accuracy, with your XL-430 installed, you do `S RebootServo 3 430 1296000 0` and you have 0.088' control, as 1 unit is 1 unit, but you have to work around DDE. Unless DDE looks at Defaults.make_ins and sees this command, and so changes the offset it applies to Joint 6 values; the 148. It would then make it 487. This would be the default setup on new robots for backwards compatibility with DDE LTS, in the Defaults.make_ins file:
````
;S RebootServo 1 430 4270909 0; Set 430 for LTS compatibility
S RebootServo 1 430 1296000 0; Set 430 for 430 units
;S RebootServo 1 430 316 0; Arcsecond mode: 1/3600' per unit
z 1000000; Let servo restart
S ServoSetX 1 65 1; Turn XC430 J7 LED ON
S ServoSetX 1 64 1; Turn XC430 torque on
z 1000000; 
S ServoSetX 1 65 0; Turn XC430 J7 LED OFF
````

**Arcsecond Mode** And finally, going forward, we should (perhaps) have DDE send J6 and J7 positions in arcseconds which would need `S RebootServo <id> 430 316 0` for an XL 430 and  `S RebootServo <id> 320 1044 0` for an XL 320. DDE would know to use arcseconds, if it saw those commands in the Defaults.make_ins file. The offset would then be zero because the XC-430 can move both positive and negative. The offset was only there to allow movement in both directions on J6 in the 320's.

Notice that the HomeOffset is applied _first_ and then the resulting value is multiplied by JointsCal. This means that the units for HomeOffset are those the user is sending. If you are sending XL-320 units, specify the offset in XL-320 units. If you are sending arcseconds, specify the offset in arcseconds. 

e.g. When the 'P' move is done:
````C
void moverobotPID(int a1,int a2,int a3,int a4,int a5) {
a1 -= HomeOffset[0];
...
a1=(int)((double)a1 * JointsCal[0]);
````
and then the movement is processed. And in the standard status values, the servo positions to be returned are computed like this:
`if(param == SLOPE_END_POSITION){return (int)((float)ServoData[3].PresentPossition * JointsCal[6-1] + HomeOffset[6-1]);}`

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-12 22:42](https://github.com/HaddingtonDynamics/Dexter/issues/94#issuecomment-673145749):

### Monitoring

Update monitor thread to read which ever servos have been rebooted, according to the type supplied. Supports up to 20 servo id's or rather servo id's 1 to 20. Only ID's 3 (J6) and 1 (J7) are currently readable via the standard status responses. 

Possibilities 
- Add additional g # status_mode's with one that only returns status data for the servos
- As above, but use the currently unused "completed time stamp" field to send in the version of the status you want back, without changing status_mode, so all the other commands will return the standard status (or which ever you selected with g # )
- As above but the special return status is a JSON array, instead of binary data.
- Add some options to the `r 0 #Servo ID, Addr, Len` read from robot command so that if only an ID is specified (no addr or len) then all the available monitor data for that servo is returned. 
- As above but if no ID, addr, or len is supplied, return the ID and current position and load of all monitored servos.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-09-04 03:49](https://github.com/HaddingtonDynamics/Dexter/issues/94#issuecomment-686886647):

For joints 6 and 7, the standard move all joints and other commands work. For additional servo id's we need to send ServoSetX commands to set the goal position. James W wrote and tested this code. It translates the desired position setting to the hex format needed to send a binary value. 

````js
function num_to_hex(num, size = 12){
    let num_array = Vector.make_matrix(1, Math.round(2 * size / 3))[0]
    let num_str = num.toString(16)
    for(let i = 0; i < num_str.length; i++){
        num_array[i] = num_str[num_str.length - i - 1]
    }
    let str = ""
    for(let i = 0; i < num_array.length ; i += 2){
        str += "%" + num_array[i + 1] + num_array[i]
    }
    return str
}

function set_430_angle(id, angle){
    let size = 12
    return make_ins("S", "ServoSetX", id, 116, size, num_to_hex(Math.round(4096 * angle / 360), size))
}


new Job({
    name: "test",
    do_list: [
        set_430_angle(4, 0),
        Robot.wait_until(1),
        set_430_angle(4, 1*90),
        Robot.wait_until(1),
        set_430_angle(4, 2*90),
        Robot.wait_until(1),
        set_430_angle(4, 3*90)
    ]
})
````

The Servo at ID 4 was setup in Defaults.make_ins with
````
S, RebootServo, 4, 430, 1296000, 0; Set 430 ID 4 for 430 units
z, 1000000; Give it time to reboot
S, ServoSet, 4, 65, 1; Turn XC430 LED on
S, ServoSet, 4, 64, 1; Turn XC430 torque on
z, 1000000; Give the operator time to see it
S, ServoSet, 4, 65, 0; Turn XC430 LED off
````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-10-08 22:53](https://github.com/HaddingtonDynamics/Dexter/issues/94#issuecomment-705864294):

Note for the future: If you run an XC-430 with commands for an XL-320, it will probably cause the servo to start reporting a hardware error, the light will blink, and it will refuse to operate. 

This happens because the goal position address for the XL-320 overlaps the Temperature Limit setting for the XC-430. And you can set a temperature limit of as little as 0'C. The servo will then only operate if it's frozen.

To verify this is the case, read back address 31 with  `r 0 #Servo 1 31 1` aka `read_from_robot("#Servo 1 31 1")` and the value returned after the `... 55 80` is the temp limit. Replace that first number with the address of the servo: 1 for J7 (as shown in the example) or 3 for J6. 

To recover from this error, send `S ServoSetX 1 31 80` (again set the first number to the servo address) and verify by reading back that the value was set. Now you can RebootServo (or just power cycle) and everything should be ok.

#### <img src="https://avatars3.githubusercontent.com/u/5458696?v=4" width="50">[jonfurniss](https://github.com/jonfurniss) commented at [2020-10-09 17:01](https://github.com/HaddingtonDynamics/Dexter/issues/94#issuecomment-706295247):

DDE currently has a built in offset when sending move all joints to J6 (servo ID 3) of 148.48° or [512](https://github.com/cfry/dde/blob/b267702f6df313faea38c3ff987868496e199bae/core/socket.js#L101) XL-320 (148.48°/0.29°/Dynamixel step) units. So a command of 0° from DDE has the XL-320 in the middle of its movement. 

When operating the XC-430s from DDE in compatibility mode, we need to account for the larger motion range of the XC-430 as well as the built in DDE offset. When parsing the RebootServo command, DexRun.c first assigns the slope, then the offset, so we need to do the offset with respect to XL-320 units, **not** XC-430 units. Dexter's 0° position is 180° off from the XC-430's 0 Dynamixel unit position, so 180°/0.29°/XL-320 step ~= 620 Dynamixel units. Then 620-512 = 108 is the offset in Defaults.make_ins that has the J6 (servo ID 3) XC-430 behaving as expected.

_Note: Changes to the code to bring it in-line with the homeoffsets for other joints mean that this value must be **negative** because it will be subtracted from the commanded position._

For setting up a gripper with Servo 3 as joint 6 and Servo 1 as joint 7, paste the following code at the bottom of Defaults.make_ins.
```
S, RebootServo, 1, 430, 4270909, 0;
z, 1000000;
S, ServoSet2X 1, 64, 1; Turn J7 XC430 torque on
S, ServoSet2X 1, 65, 1; Turn J7 XC430 LED on
S, RebootServo, 3, 430, 4270909, -108;
z, 1000000;
S, ServoSet2X 3, 64, 1; Turn J6 XC430 torque on
S, ServoSet2X 1, 65,0; Turn J7 XC430 LED off
```


-------------------------------------------------------------------------------

# [\#93 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/93) `open`: XBOX controllers on Dexter?
**Labels**: `Firmware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-06-30 18:27](https://github.com/HaddingtonDynamics/Dexter/issues/93):

It looks like there are drivers and controller to keyboard / mouse mapping software available for Ubuntu
https://www.maketecheasier.com/set-up-xbox-one-controller-ubuntu/

This could make a very nice mode switching tool for PhUI GUI or other Job Engine programs. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-10-05 20:03](https://github.com/HaddingtonDynamics/Dexter/issues/93#issuecomment-703858304):

Current version of code that supports the standard XBOX controllers. There are some issues with this code which need fixing. e.g. it drifts. 
[GameController.zip](https://github.com/HaddingtonDynamics/Dexter/files/5329817/GameController.zip)


-------------------------------------------------------------------------------

# [\#92 PR](https://github.com/HaddingtonDynamics/Dexter/pull/92) `closed`: Step angles

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-06-17 00:47](https://github.com/HaddingtonDynamics/Dexter/pull/92):

Bringing in all the changes made on StepAngles branch, to the new non-dated Stable_Condrive branch. The Stable_2020_02_04_ConeDrive will always be there, unchanged. 




-------------------------------------------------------------------------------

# [\#91 PR](https://github.com/HaddingtonDynamics/Dexter/pull/91) `closed`: pid_move_to added

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) opened issue at [2020-06-16 03:00](https://github.com/HaddingtonDynamics/Dexter/pull/91):

Two new oplets are added:

-'C' for pid_move_to
  Takes a range of 9 to 11 arguments.
   J6 and J7 are optional, default by not passing in or set to Null/NaN:
      x, y, z, dir_x, dir_y, dir_z, config_a, config_b, config_c, J6, J7
   xyz's are in integer microns.
   dir's are floating point vector components.
   config's are booleans (0 or 1)
   J6 and J7 are in Dynamixel units (512 = 297 degrees)
   See oplet 'M': https://github.com/HaddingtonDynamics/Dexter/wiki/Command-oplet-instruction

-'D' for pid_move_to_straight
  Oplet has been added but not been implemented
  Will require sleeps in between interpolated steps,
  not sure how to handle this in DexRun, may need FPGA queue.
  Same arguments as move_to plus maybe a sleep duration or speed.




-------------------------------------------------------------------------------

# [\#90 PR](https://github.com/HaddingtonDynamics/Dexter/pull/90) `closed`: Verify returned Dyamixel Status Data

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-06-16 02:35](https://github.com/HaddingtonDynamics/Dexter/pull/90):

From time to time, the status data read back from the Dynamixel servos may be garbled or have errors. This has been observed randomly, and would cause momentary errors or twitches in recorded data while in follow mode. This commit adds full checking for the returned data and discards packets that have errors.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-17 23:03](https://github.com/HaddingtonDynamics/Dexter/pull/90#issuecomment-645670489):

No need for separate merge as StepAngles branch had all this and it is now merged into the new Stable_Conedrive (note: Stable_2020_02_04_ConeDrive branch still exists and should be unchanged)


-------------------------------------------------------------------------------

# [\#89 PR](https://github.com/HaddingtonDynamics/Dexter/pull/89) `closed`: FPGA Shadow_map / Allow non-Dynamixel end effector

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-06-16 02:14](https://github.com/HaddingtonDynamics/Dexter/pull/89):

The goal is to provide more flexible use of the wires at the end effector. Right now, no matter what you do, the blue wire will automatically revert to driving Dynamixel servos. To avoid this, we must keep track of the mode the FPGA has been put in, and if it's NOT the Dynamixel mode (Dynamixel packets sent on blue and return serial on green) then it doesn't force it into that mode. To keep track of what's going on in the FPGA we add a ram array and shadow every FPGA write into that RAM copy, so we can move it back. That sets us up for supporting "read FPGA" set parameter in the future as well. 

We also re-add the END_EFFECTOR_IO, SERVO_SETPOINT_A, SERVO_SETPOINT_B mappings to the OldMemMapInderection so that the associated SetParameters can work again. 

This commit basically duplicates:
https://github.com/HaddingtonDynamics/Dexter/commit/31c1e41f59eb86452bd60402ce426722c248e1ff
and 
https://github.com/HaddingtonDynamics/Dexter/commit/9718c9e49224d4deeaacba39f92bc7cb9f036759
and is a second take on closing issue #73

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-17 23:03](https://github.com/HaddingtonDynamics/Dexter/pull/89#issuecomment-645670707):

No need for separate merge as StepAngles branch had all this and it is now merged into the new Stable_Conedrive (note: Stable_2020_02_04_ConeDrive branch still exists and should be unchanged)


-------------------------------------------------------------------------------

# [\#88 PR](https://github.com/HaddingtonDynamics/Dexter/pull/88) `closed`: Web

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-06-10 01:31](https://github.com/HaddingtonDynamics/Dexter/pull/88):

Adds the ability to edit files on the robot via web browser. Changes the web server to support serving all files under /srv/samba/share (vs just the files under /srv/samba/share/www previously) and adds functions for saving modified versions of those files back (while checking and retaining permissions) and for uploading or creating new files. The editor is based on 
https://github.com/ajaxorg/ace-builds
and supports syntax highlighting for javascript (and it knows .dde is javascript), C / C++, bash (e.g. RunDexRun) and a few other files we might have on Dexter as well as standard text files. The idea is stolen from 
https://github.com/me-no-dev/ESPAsyncWebServer/blob/master/src/edit.htm 
and modified to better fit the Dexter environment. e.g. to support changing folders, longer lists of files, etc... than you might find on the ESP-8266 uC. 

Nothing in this pull should cause /any/ problems with the robots essential functions. 

Closes:
https://github.com/HaddingtonDynamics/Dexter/issues/85





-------------------------------------------------------------------------------

# [\#87 PR](https://github.com/HaddingtonDynamics/Dexter/pull/87) `closed`: Update RunDexRun

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-06-10 01:19](https://github.com/HaddingtonDynamics/Dexter/pull/87):

Move the automatic execution of Job Engine jobs on startup, out of RunDexRun and into a separate text file called autoexec.jobs




-------------------------------------------------------------------------------

# [\#86 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/86) `closed`: Simplify control of the jobs that start with the robot.
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-06-01 23:56](https://github.com/HaddingtonDynamics/Dexter/issues/86):

When a Dexter starts, the job engine is available to automatically start jobs. For example Dexters are often shipped with [PhUI](https://github.com/HaddingtonDynamics/Dexter/wiki/PhysicalUserInterface) starting automatically after startup.

When jobs are running, they monopolize the DexRun firmware. That keeps DDE from talking to the robot, and confuses users who want to write jobs. 

At this time, the way to start jobs on boot up is to add them to the end of the RunDexRun script. This script also sets a few critical items in the robots, and is responsible for starting the DexRun firmware (it's right there in the name). 

So to change what is running on bootup, the user has to edit the RunDexRun file. And not damage it in unintentional ways. And keep the correct execute permissions, or repair them with `chmod +x RunDexRun` from the SSH prompt. 

To avoid this, we can add the following code to the end of RunDexRun in place of the hard coded job start commands:

```bash
#Start default jobs from autoexec.jobs
sleep 5 #give DexRun time to finish starting
#https://stackoverflow.com/questions/1521462/looping-through-the-content-of-a-file-in-bash
while read -u 10 job; do # the -u 10 uses pipe 10 in place of stdin

  if [[ $job =~ ^#.* ]]
  then
    echo "Ignoring $job"
  else
    if [[ -e /srv/samba/share/dde_apps/$job ]] 
    then
      cd /root/Documents/dde
      echo "/srv/samba/share/dde_apps/$job"
      sudo node core define_and_start_job /srv/samba/share/dde_apps/$job
      sleep 1
    else
      echo "$job not found"
    fi
  fi
done 10< autoexec.jobs 
# pipe to 10 so dde doesn't read lines from autoexec.jobs via stdin
```
and then in a few file /srv/samba/share/autoexec.jobs, list the jobs you want to run from the /srv/samba/share/dde_apps folder. e.g.

```
#helloworld.dde
PHUI2RCP.js
````

This file, being a simple text list of job names, is much easier to edit without causing damage. And even if it IS damaged, RunDexRun will still start the robot and make the firmware accessible to DDE so that it can be fixed. 

Note that jobs can be "commented out" by adding a # to the start of the line 




-------------------------------------------------------------------------------

# [\#85 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/85) `open`: Browser based editing of files on Dexter via node web server
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-05-30 06:40](https://github.com/HaddingtonDynamics/Dexter/issues/85):

Updating / editing files on Dexter can be difficult without the support of Samba, which is not supported in recent versions of WIndows ( see issue #58 ). Of course, [we can SSH](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#shell-access-via-ssh) in, but many users are not experienced with this method and the nano or vim editors leave much to be desired. 

The [Ace editor](https://ace.c9.io/) is very capable and quite compact, at only 354kb for a full featured editor, with all the standard features, and code editing, parentheses highlighting, syntax checking (lint) for C, C++, JavaScript, CSS, and HTML among others.

With this editor available on Dexter via a standard browser, anyone can edit firmware, job files, settings files (.make_ins), as well as scripts, etc...

To install this on Dexter, first the node web engine is required. See [Node.js web server](https://github.com/HaddingtonDynamics/Dexter/wiki/nodejs-webserver)
1. https://github.com/node-formidable/formidable
is required to process the POST data coming back when a file is saved. It must be installed on Dexter [while the robot is connected to the internet](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#internet-access), via 
`npm install formidable` from the /srv/samba/share folder. 
2. a new folder called "edit" needs to be created under /srv/samba/share/www. 
3. In /srv/samba/share/edit, the files "edit.html", "page.png", "folder.png", and "ace.js" must be added. Several other files are required for syntax highlighting and search. All the files are available from the "web" branch off the stable branch from the repo:
https://github.com/HaddingtonDynamics/Dexter/compare/Stable_2020_02_04_ConeDrive...web
Note: Credit for the edit.html file (which some modifications) should be given to:
https://github.com/me-no-dev/ESPAsyncWebServer/blob/master/src/edit.htm
4. In /srv/samba/share/www/index.html a link to the edit function should be added. (also in the web branch)
5. the `/srv/samba/share/www/httpd.js` file must be edited (as it is on the web branch) to add 
`const formidable = require('formidable')`
near the start and to replace the standard web server section with:
````js

function isBinary(byte) { //must use numbers, not strings to compare. ' ' is 32
  if (byte >= 32 && byte < 128) {return false} //between space and ~
  if ([13, 10, 9].includes(byte)) { return false } //or text ctrl chars
  return true
}

//standard web server on port 80 to serve files
var http_server = http.createServer(function (req, res) {
  //see https://nodejs.org/api/http.html#http_class_http_incomingmessage 
  //for the format of q. 
  var q = url.parse(req.url, true)
  console.log("web server passed pathname: " + q.pathname)
  if (q.pathname === "/") {
      q.pathname = "index.html"
  }
  if (q.pathname === "/init_jobs") {
      serve_init_jobs(q, req, res)
  }
  else if (q.pathname === "/edit" && q.query.list ) { 
    let path = SHARE_FOLDER + q.query.list
    console.log("File list:"+path)
    fs.readdir(path, {withFileTypes: true}, 
      function(err, items){ //console.log("file:" + JSON.stringify(items))
        let dir = []
        if (q.query.list != "/") { //not at root
          dir.push({name: "..", size: "", type: "dir"})
          }
        for (i in items) { //console.log("file:", JSON.stringify(items[i]))
          if (items[i].isFile()) { 
            let stats = fs.statSync(path + items[i].name)
            let size = stats["size"]
            dir.push({name: items[i].name, size: size, type: "file"})
            } //size is never actually used.
          else if (items[i].isDirectory()) {
            dir.push({name: items[i].name, size: "", type: "dir"})
            } //directories are not currently supported. 
          }
        res.write(JSON.stringify(dir))
        res.end()
      })
    }
  else if (q.pathname === "/edit" && q.query.edit ) { 
    let filename = SHARE_FOLDER + q.query.edit
    console.log("serving" + filename)
    fs.readFile(filename, function(err, data) {
        if (err) {
            res.writeHead(404, {'Content-Type': 'text/html'})
            return res.end("404 Not Found")
        }
        let stats = fs.statSync(filename)
        console.log(("permissions:" + (stats.mode & parseInt('777', 8)).toString(8)))
        for (let i = 0; i < data.length; i++) { 
          if ( isBinary(data[i]) ) { console.log("binary data:" + data[i] + " at:" + i)
            res.setHeader("Content-Type", "application/octet-stream")
            break
            }
          }
        res.writeHead(200)
        res.write(data)
        return res.end()
      })
    }
    else if (q.pathname === "/edit" && req.method == 'POST' ) { //console.log("edit post file")
        const form = formidable({ multiples: false });
        form.once('error', console.error);
        const DEFAULT_PERMISSIONS = parseInt('644', 8)
        var stats = {mode: DEFAULT_PERMISSIONS}
        form.on('file', function (filename, file) { 
          try { console.log("copy", file.path, "to", SHARE_FOLDER + file.name)
            stats = fs.statSync(SHARE_FOLDER + file.name) 
            console.log(("had permissions:" + (stats.mode & parseInt('777', 8)).toString(8)))
          } catch {} //no biggy if that didn't work
          fs.copyFile(file.path, SHARE_FOLDER + file.name, function(err) {
            let new_mode = undefined
            if (err) { console.log("copy failed:", err)
              res.writeHead(400)
              return res.end("Failed")
              }
            else {
              fs.chmodSync(SHARE_FOLDER + file.name, stats.mode)
              try { //sync ok because we will recheck the actual file
                let new_stats = fs.statSync(SHARE_FOLDER + file.name)
                new_mode = new_stats.mode
                console.log(("has permissions:" + (new_mode & parseInt('777', 8)).toString(8)))
              } catch {} //if it fails, new_mode will still be undefined
              if (stats.mode != new_mode) { //console.log("permssions wrong")
                //res.writeHead(400) //no point?
                return res.end("Permissions error")
                }
              fs.unlink(file.path, function(err) {
                if (err) console.log(file.path, 'not cleaned up', err);
                }); 
              res.end('ok');
              }
            }) //done w/ copyFile
          });
        form.parse(req)
        //res.end('ok');
      // });
      }
      else if (q.pathname === "/edit" && req.method == 'PUT' ) { console.log('edit put')
        const form = formidable({ multiples: true });
        form.parse(req, (err, fields, files) => { //console.log('fields:', fields);
          let pathfile = SHARE_FOLDER + fields.path
          fs.writeFile(pathfile, "", function (err) { console.log('create' + pathfile)
            if (err) {console.log("failed", err)
              res.writeHead(400)
              return res.end("Failed:" + err)
              }
           res.end('ok'); //console.log('done');
           }); 
          });
        }
      //else if(q.pathname === "/job_button_click") {
  //	  serve_job_button_click(q, req, res)
  //}
  //else if(q.pathname === "/show_window_button_click") {
  //	  serve_show_window_button_click(q, req, res)
  //} 
  else {
  	  serve_file(q, req, res)
  }
})

````
_Note: The version on the web branch also has the changes required to better support running job engine jobs with a full 2 way interface allowing show_dialog calls to appear in the browser._

Limitations: 
- only the /srv/samba/share folder is presented for editing. There is no method for traversing into other folders above that. 

DONE: Testing. Not sure if it screws up executable flags. May need to check and chmod / chown after writing new files. 
DONE: Add support for changing directories. 
DONE: Figure out what to do about binary / very large files. The editor now allows you to edit all files, but warns if the file is very large or if binary codes are detected in the file. 
DONE: Create new files. 
DONE: Upload files. 
DONE: Delete files? Or just move to /tmp folder
DONE: Chmod files? e.g. toggle executable. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-28 21:54](https://github.com/HaddingtonDynamics/Dexter/issues/85#issuecomment-665303065):

TODO: Add a button to the editor to set the time on Dexter from the browsers time.
TODO: Find some way to recompile DexRun.c to DexRun via a button in the editor.


-------------------------------------------------------------------------------

# [\#84 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/84) `open`: Add modbus server support to Dexter
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-05-26 03:48](https://github.com/HaddingtonDynamics/Dexter/issues/84):

Some support for modbus via the Job Engine or PC versions of DDE has been documented here:
https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-ModBus
This allows jobs to act as modbus clients and make requests of other modbus devices which include a server function. It is also possible to start a job, start a modbus server via the library in that job, and then act as a modbus server as long as the job is running.

It may be more reliable and simpler to include a modbus server function as a part of the node server which already provides a websocket proxy and web server:
https://github.com/HaddingtonDynamics/Dexter/wiki/nodejs-webserver
The primary advantage is that this is generally always running as long as the robot is on, and since it typically isn't changed, it can (hopefully) be more reliable. 

The expected use case is that a modbus device could send a request to Dexter and know that it would be recieved. The question is: What to do with that request?

Dexter doesn't have relays or coils or even individual actuators other than it's joints. However, it can run jobs. One idea is to map setCoil requests to starting jobs. E.g. setCoil 1 on would start /srv/samba/share/dde_app/modbus1.dde. The same request with "off" instead of "on" would kill that job. ReadCoil 1 would return the status of the job: true for running, false if not running. 

While the job is running, it could output data back to the modbus system via a special version of the "out" command and so set holding register values for other modbus devices to read. 

Of course, the job could also send modbus commands to other devices directly.

We can imagine a new Dexter owner who wants to integrate the arm into an existing assembly line. They might use DDE's record panel to put the robot into follow mode, record a simple movement that picks up a box and sets it down out of the way, and then save that job to the robot as "/srv/samba/share/dde_apps/modbus1.dde" and then program the line to send a setCoil 1 true when the box is ready. Done, and basically zero programming. 

But then, maybe they need to send back a message to the line to tell it that it can send Dexter the next box. This code can be added to the job with some programming [as per the existing example](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-ModBus#modbus-tcp), or with a single "out" command a register can be set and the line can be programmed to check that register on a regular interval. (It is probably possible to make the sending of a simple modbus command from a job much easier, but that would have to be done in DDE / Job Engine)

To allow Dexter to always response to ModBus commands from another source including the basic functionality of setting and getting registers, and starting a job, then reading back values we can add some code to the [built in web server](https://github.com/HaddingtonDynamics/Dexter/wiki/nodejs-webserver). To use this, you must first [SSH into Dexter](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#shell-access-via-ssh) and then<BR>
````
cd /srv/samba/share
node install modbus-serial
````

and then add the following to /srv/samba/share/www/httpd.js
````js
// ModBus client server
const ModbusRTU = require("modbus-serial");
var modbus_reg = []

function modbus_startjob(job_name) {
	console.log(job_name)
	let jobfile = DDE_APPS_FOLDER + job_name + ".dde"
	let job_process = get_job_name_to_process(job_name)
	if(!job_process){
	    console.log("spawning " + jobfile)
	    //https://nodejs.org/api/child_process.html
	    //https://blog.cloudboost.io/node-js-child-process-spawn-178eaaf8e1f9
	    //a jobfile than ends in "/keep_alive" is handled specially in core/index.js
	    job_process = spawn('node',
		["core define_and_start_job " + jobfile],   
		{cwd: DDE_INSTALL_FOLDER, shell: true}
		)
	    set_job_name_to_process(job_name, job_process)
	    console.log("Spawned " + DDE_APPS_FOLDER + job_name + ".dde as process id " + job_process)
	    job_process.stdout.on('data', function(data) {
		console.log("\n\n" + job_name + ">'" + data + "'\n")
		let data_str = data.toString()
		if (data_str.substr(0,7) == "modbus:") { //expecting 'modbus: 4, 123' or something like that
		    [addr, value] = data_str.substr(7).split(",").map(x => parseInt(x) || 0)
		    modbus_reg[addr] = value
		//TODO: Change this to something that allows multiple values to be set in one out.
		    }
		})
	 
	    job_process.stderr.on('data', function(data) {
	  	console.log("\n\n" + job_name + "!>'" + data + "'\n")
		//remove_job_name_to_process(job_name) //error doesn't mean end.
		})
	    job_process.on('close', function(code) {
		console.log("\n\nJob: " + job_name + ".dde closed with code: " + code)
		//if(code !== 0){  } //who do we tell if a job crashed?
		remove_job_name_to_process(job_name)
		})
	    }
	else {
	    console.log("\n" + job_name + " already running as process " + job_process)
	    } //finished with !job_process
	}

var vector = {
    //TODO: Figure out what to return as inputs.
    // Possible: Values from a file? 
    // e.g. modbus.json has an array where jobs can store data to be read out here.
    // maybe that is the modbus_reg array as a json file?
    getInputRegister: function(addr) { //doesn't get triggered by QModMaster for some reason.
	//This does work mbpoll -1 -p 8502 -r 2 -t 3 192.168.0.142 
        console.log("read input", addr)
        return addr; //just sample data
        },
    getMultipleInputRegisters: function(startAddr, length) {
        console.log("read inputs from", startAddr, "for", length); 
        var values = [];
        for (var i = startAddr; i < length; i++) {
            values[i] = startAddr + i; //just sample return data
            }
        return values;
        },
    getHoldingRegister: function(addr) {
        let value = modbus_reg[addr] || 0
        console.log("read register", addr, "is", value)
        return value 
        },
    getMultipleHoldingRegisters: function(startAddr, length) {
        console.log("read registers from", startAddr, "for", length); 
        let values = []
        for (var i = 0; i < length; i++) {
            values[i] = modbus_reg[i] || 0
            }
        return values
        },
    setRegister: function(addr, value) { 
        console.log("set register", addr, "to", value) 
        modbus_reg[addr] = value
        return
        },
    getCoil: function(addr) { //return 0 or 1 only.
        let value = ((addr % 2) === 0) //just sample return data
        console.log("read coil", addr, "is", value)
        return value 
        //TODO Return the status of the job modbuscoil<addr>.dde
        // e.g. 1 if it's running, 0 if it's not.
        },
    setCoil: function(addr, value) { //gets true or false as a value.
        console.log("set coil", addr, " ", value)
	if (value) { modbus_startjob("modbus" + addr) }
	else { console.log("stop") }
        //TODO Start or kill job modbuscoil<addr>.dde depending on <value>
        // Maybe pass in with modbus_reg as a user_data? or they can access the file?
        return; 
        },
    readDeviceIdentification: function(addr) {
        return {
            0x00: "HaddingtonDynamics",
            0x01: "Dexter",
            0x02: "1.1",
            0x05: "HDI",
            0x97: "MyExtendedObject1",
            0xAB: "MyExtendedObject2"
        };
    }
};

// set the server to answer for modbus requests
console.log("ModbusTCP listening on modbus://0.0.0.0:8502");
var serverTCP = new ModbusRTU.ServerTCP(vector, { host: "0.0.0.0", port: 8502, debug: true, unitID: 1 });

serverTCP.on("initialized", function() {
    console.log("initialized");
});

serverTCP.on("socketError", function(err) {
    console.error(err);
    serverTCP.close(closed);
});

function closed() {
    console.log("server closed");
}
````

The following sample job sets register 1 to 123 (and could, of course, move the robot or do whatever) and is activated when Dexter is told to set coil 1 to true. 
`/srv/samba/share/dde_apps/modbus1.dde
````js

function modbus_setreg(reg, value) {
	console.log("modbus:", reg, ",", value)
	}

new Job({name: "modbus1", 
    do_list: [
        //Robot.out("modbus: 1, 123")
	function() {modbus_setreg(1, 123)}
        ]
    })
    
````

Or see the complete file here:<br>
https://github.com/HaddingtonDynamics/Dexter/blob/Stable_Conedrive/Firmware/www/httpd.js

Notes:
https://sourceforge.net/projects/qmodmaster/ is a wonderful tool for Windows, GUI, easy to use, clear interface. Hit the CAT5 icon, enter Dexters IP and port 8502, then select unit ID 1, select the address, length, and on you go.

https://github.com/epsilonrt/mbpoll provides modbus client testing tool for Ubuntu. e.g. `mbpoll -1 -p 8502 -t 0 192.168.1.142` connects to the Dexter at .142 on the local network, via port 8502, and reads coil 0. To set a coil, add a 0 or 1 at the end of the command. To read coil 1, the option is `-r 2` unless you include the `-0` option, then it's `-r 1`. e.g. to read coil 2, either of these provide the same response:
````
>mbpoll -0 -1 -r 2 -t 0 -p 8502 192.168.1.142
>mbpoll -1 -r 3 -t 0 -p 8502 192.168.1.142
mbpoll 1.4-12 - FieldTalk(tm) Modbus(R) Master Simulator
Copyright © 2015-2019 Pascal JEAN, https://github.com/epsilonrt/mbpoll
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions; type 'mbpoll -w' for details.

Protocol configuration: Modbus TCP
Slave configuration...: address = [1]
                        start reference = 3, count = 1
Communication.........: 192.168.1.142, port 8502, t/o 1.00 s, poll rate 1000 ms
Data type.............: discrete output (coil)

-- Polling slave 1...
[3]: 	1
````

To set coil 1, use `mbpoll -0 -1 -p 8502 -r 1 -t 0 192.168.1.142 1`

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-13 17:55](https://github.com/HaddingtonDynamics/Dexter/issues/84#issuecomment-657703653):

This is being made part of the standard software in the "Stable_Conedrive" branch. Once that is released, we can close this issue.


-------------------------------------------------------------------------------

# [\#83 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/83) `open`: Enabling mDNS "bonjour" hostname.local support on Dexter
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-05-26 01:55](https://github.com/HaddingtonDynamics/Dexter/issues/83):

mDNS is a service that allows local devices to put their names into the local network for resolution instead of ip address, without requiring standard DNS records. 
https://en.wikipedia.org/wiki/Multicast_DNS
It is used by the Apple Bonjour service and is support on Linux via Avahi and is not supported in Windows 10. The advantage is that each Dexter could be found on the local network by entering it's hostname, followed by ".local" into the browser or other network address. 

All that is required is to set the robots name in the `/etc/hostname` file. For example, on my robot, that file contains a single line: `DEX-197121` then, for example, I can go to:
http://DEX-197121.local 
and the onboard node server well respond with the web page. Or I can ping 'DEX-197121.local' 

If we automatically set this from Dexters serial number, users could just glance at the serial number plate and not have to find the IP address. It would be easy to add this to the current functionality in RunDexRun which sets the mac address from the serial number to avoid mac address crashes on the network (all of the microZed boards come with the same mac address). 

Of course, that depends on the Defaults.make_ins file having the serial number in it in the format that RunDexRun expects: DEX-####### where the '#'s are replaced with the serial number. Including _different_ letters at the start (other than "DEX") increases the number of possible combinations past what is possible in the mac address, so that must _always_ start with "DEX-"

Another option is to manually edit that file when a new robot is commissioned as part of the calibration instructions. In that case, any valid domain name is possible. E.g. you could have "HDI-123456". Or you could even have a customer supplied nickname like "fred" and reach it at fred.local

It would also be possible to have some sort of configuration script via command line, DDE, or the web browser which collects information and then sets this (and possibly other things) as a result. 

(Note: This issue is just to document work that was done in January with Phil Joy which was not implemented or documented previously) 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-07 19:00](https://github.com/HaddingtonDynamics/Dexter/issues/83#issuecomment-640263901):

I've done a little testing on this mDNS now that I'm switching to Ubuntu 16.04 as my work OS. Previously, the version of Windows I've used doesn't support mDNS so it not working there is expected. What I've found is that I can `ping dex-197121.local` and it resolves to the correct IP instantly. But if I try to browse to http://dex-197121.local the browser (Chrome or Firefox) hangs waiting for the page to load. By watching the web server logs in the robot, I can see that the request did reach it, and the page was supposedly written back, but the browser doesn't seem to get it. The same browser, same window, works perfectly when given the ip address instead. I've searched and found other people reporting multiple other problems, but not this exact thing. This one is close (different version of Ubuntu and using Chromium, not Chrome)
https://superuser.com/questions/1354448/chromium-on-ubuntu-doesnt-resolve-local-address-though-other-applications-do

Someone with a mac, and someone with Windows 10 should really try this and see if it works.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-13 17:56](https://github.com/HaddingtonDynamics/Dexter/issues/83#issuecomment-657704061):

"Someone with a mac, and someone with Windows 10 should really try this and see if it works."


-------------------------------------------------------------------------------

# [\#82 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/82) `open`: Interface with Pickit vision system
**Labels**: `enhancement`, `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-05-20 17:02](https://github.com/HaddingtonDynamics/Dexter/issues/82):

If we want to try to interface with this vision system, the protocol is buried in their documentation here:
https://docs.pickit3d.com/docs/pickit/en/2.3/robot-integrations/robot-independent/socket/index.html
It's based on CAT5 / TCP/IP to port 5001 so we should be able to setup a node.js server on the robot to listen on that port and interpret their commands into our oplets given some programming time. 






-------------------------------------------------------------------------------

# [\#81 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/81) `closed`: Not able to interface the dexter arm with my PC having ubuntu 18.04

#### <img src="https://avatars1.githubusercontent.com/u/57145926?v=4" width="50">[sumr4693](https://github.com/sumr4693) opened issue at [2020-05-16 17:55](https://github.com/HaddingtonDynamics/Dexter/issues/81):

Hi,

I have not worked related to ethernet devices before, and so I have difficulties in interfacing my PC with the Dexter robot arm. I followed the instructions given in the website:

1. I set my ethernet adapter IP address to : 192.168.1.100 (for example) and subnet mask: 255.255.255.0
2. I connected the CAT 6a (tried also with new CAT 5e cable as well)  ethernet cable, which I found in the robot arm kit, between PC and dexter arm.
3. I tried to ping the dexter arm (whose default address is supposed to be 192.168.1.142) from both the command terminal and DDE interface. But I didn't get any response.
4. I tried the above steps for IP address for '0-255 in the last section for both 192.168.1.* and 192.168.0.* (after I kept my PC IP as 192.168.0.100) as well. But no response again.
5. I also tried by reinserting the mounted SD card in the board, and by switching off my WiFi when pinging the arm. But nothing worked.

Is there someway I can find the dexter ip address either from the physical connection, or by using and reading from the SD card? Please help me to fix this.

Thanks in advance!

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-05-16 19:34](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-629695773):

Please try the USB connection as per:
https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-USB-Connection
that will work IF the redboard is booting. Also check the troubleshooting page on the wiki to verify you are getting the expected lights on the board when it boots.

#### <img src="https://avatars1.githubusercontent.com/u/57145926?v=4" width="50">[sumr4693](https://github.com/sumr4693) commented at [2020-05-16 21:06](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-629705722):

Thank you very much for your immediate response! Ok I will try these and let you know.

#### <img src="https://avatars1.githubusercontent.com/u/57145926?v=4" width="50">[sumr4693](https://github.com/sumr4693) commented at [2020-05-18 12:11](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-630139912):

I made the USB connection between dexter and PC, and got the following boot commands from the dexter:

![Screenshot from 2020-05-18 14-04-45](https://user-images.githubusercontent.com/57145926/82211215-cd3bdb80-9910-11ea-959a-22878bfd9558.png)
![Screenshot from 2020-05-18 13-57-15](https://user-images.githubusercontent.com/57145926/82211281-e775b980-9910-11ea-87dd-49db431c6d88.png)
![Screenshot from 2020-05-18 13-57-47](https://user-images.githubusercontent.com/57145926/82211279-e6dd2300-9910-11ea-83b0-f7356e28cef3.png)
![Screenshot from 2020-05-18 13-58-24](https://user-images.githubusercontent.com/57145926/82211276-e6448c80-9910-11ea-8326-3b94608f7856.png)
![Screenshot from 2020-05-18 13-58-49](https://user-images.githubusercontent.com/57145926/82211272-e5abf600-9910-11ea-8e9b-589292c1147b.png)
![Screenshot from 2020-05-18 13-59-09](https://user-images.githubusercontent.com/57145926/82211268-e5135f80-9910-11ea-8f9e-9423d0564377.png)
![Screenshot from 2020-05-18 13-59-42](https://user-images.githubusercontent.com/57145926/82211265-e3e23280-9910-11ea-87a2-4af0f4cfa37f.png)
![Screenshot from 2020-05-18 14-00-03](https://user-images.githubusercontent.com/57145926/82211263-e3499c00-9910-11ea-83b4-a6f014f5899e.png)

I see an error in the last image. From this info, will I be able to find anything useful to figure out the ethernet communication issue? Thanks in advance!

#### <img src="https://avatars1.githubusercontent.com/u/57145926?v=4" width="50">[sumr4693](https://github.com/sumr4693) commented at [2020-05-18 12:14](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-630141631):

Also, I checked the LEDs status when booting:
Green: steady 'ON' (Power LED)
Blue: steady 'ON' (related to FPGA)
Red: 'ON' for few seconds and then 'OFF' (related to disk access to SD card)

Is Red LED functioning a normal behaviour?

#### <img src="https://avatars1.githubusercontent.com/u/57145926?v=4" width="50">[sumr4693](https://github.com/sumr4693) commented at [2020-05-18 12:23](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-630146667):

Regarding the jumper configuration:

To boot from SD card, I saw that the jumpers should have the connections JP1: 1-2, JP2: 2-3, JP3: 2-3

And this is the image with the jumper connections:
![dexter_jumpers](https://user-images.githubusercontent.com/57145926/82212274-936bd480-9912-11ea-9909-4a3a727beda8.jpg)

The markings JP1, JP2 and JP3 in the microzed board seen above, are on the different locations from the board which is seen in Troubleshooting page. And I could see "1" on either sides of the three pins for each jumper, so it's confusing to locate the first pin for each jumper. I hope that the board in the attached image is the revised version.

Kindly clarify how to locate the numbers 1,2,3 for each jumper.

Thank you!

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-05-18 20:41](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-630424285):

Now I'm confused. I'm not aware of any changes to the labeling on the microzed board. Can you post a picture of your board showing that area? I'm checking with the group to see if they are aware of a change... what name did you order the kit under?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-05-18 20:44](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-630425691):

In any case, based on your prior post of the USB data, it appears the jumpers are in the correct location, but the SD card isn't working correctly. e.g. it can't mount the ext partition and start the OS. It IS able to read the FAT partition and start the .bit file. I would re-burn the SD card from the image or contact sales for a replacement.

#### <img src="https://avatars1.githubusercontent.com/u/57145926?v=4" width="50">[sumr4693](https://github.com/sumr4693) commented at [2020-05-19 14:15](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-630847943):

Thanks for figuring out the issue! I connected the SD card via card reader to my PC, and I am seeing a 16 GB volume drive (the list of files: boot.bin, devicetree.dtb, DexRun.c, uImage, xillydemo.bit and a folder - System Volume Information) and a 8 GB volume drive (I think this may be the ext partition)  
1. I don't find the details from the "SD card image" page on what the image file does look like. I will be using Etcher to flash the image, since my PC is Ubuntu based. Does Etcher automatically take care of the ext partition in the SD card? Is it just enough to add the flash file and select "Flash"? Or do I need to delete the contents or format the SD card?
2. In the "SD card image" page, it is mentioned to contact you to get the image file. Can you please provide the image file? 

This is the 16 GB volume drive screenshot:
![16_GB_vol](https://user-images.githubusercontent.com/57145926/82337039-95559680-99eb-11ea-96cd-725d39ee3b17.png)
This is the 8 GB volume drive screenshot:
![8GB_vol](https://user-images.githubusercontent.com/57145926/82337071-a30b1c00-99eb-11ea-8c79-f862cf169feb.png)

If this reburning doesn't work either, my company supervisor will be contacting sales team of Haddington Dynamics.

Thank you!

#### <img src="https://avatars1.githubusercontent.com/u/57145926?v=4" width="50">[sumr4693](https://github.com/sumr4693) commented at [2020-05-19 14:29](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-630857180):

This is the microzed board image from the troubleshooting page:
![troubleshooting_page_microzed](https://user-images.githubusercontent.com/57145926/82337878-8cb19000-99ec-11ea-9d27-ccb368042c84.png)
And this is the microzed board I have in the robot arm:
![my_microzed](https://user-images.githubusercontent.com/57145926/82338221-ed40cd00-99ec-11ea-9c0b-202997cc7d64.png)

If you see both the images, the markings of JP1, JP2, JP3 are on the opposite sides. So I was wondering if there is any chance that the numbers 1,2,3 could also be reversed.

And, for your information, this robot arm was exported on May 9, 2019 from Haddington Dynamics. I am just a master thesis student, so I don't know regarding the order details. But the invoice has "Industrial Robots, NESOI" under description. Does this help?

Thanks!

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-05-19 20:51](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-631075722):

Can you email jamesnewton@hdrobotic.com so we can email you a link to the SD card image? And also, in the email please include what institution you are with and who your supervisor is so we can look this up in the sales db and provide appropriate support? Thank you. 

To clarify why that is important: Every Dexter has unique calibration data onboard. Re-imaging the card will loose that data. If we have it here, then we can send it to you, but we need to understand which Dexter that is, and knowing who it was sold to is the best way to do that. If you are able to read out the files from the /srv/samba/share folder on the SD cards ext4 partition, and save them before re-loading it, that would also be good.

Also, there are a few different models of Dexter and we need to know if this is an HD, or an HDI, as they have different configuration files as well. Those are setup on different images, so we need to know what robot it is before we can provide the correct image for the SD card. Again, those are in /srv/samba/share if you can back them up yourself. 

Also, I'm concerned that the SD card itself may be defective, and if that's the case, we would want to replace it, if the robot is still under warranty. Warranty depends on the terms of the sale, so again, we need to understand what robot this is. 

Hope that makes sense, and please trust that we will do everything we can to get you back up and running. 

I will close this issue and we can continue support via email. I'm assuming something was damaged on the SD and it should be replaced rather than just re-imaged, but we can try that first.

#### <img src="https://avatars1.githubusercontent.com/u/57145926?v=4" width="50">[sumr4693](https://github.com/sumr4693) commented at [2020-05-20 11:21](https://github.com/HaddingtonDynamics/Dexter/issues/81#issuecomment-631413016):

Sure! I will contact you. Thank you for providing the email id!


-------------------------------------------------------------------------------

# [\#80 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/80) `closed`: Add VPN service, allow VPN connections to Dexter

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2020-04-11 20:43](https://github.com/HaddingtonDynamics/Dexter/issues/80):

Since Windows 10 up no longer reliably allows connection to SAMBA shares, #58 setting up a VPN server on Dexter to re-enable access to that may be a more attractive option than [SFTP](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#sftp). 

There are many options. "The wonderful thing about Standards is that there are so many from which to choose."

[OpenVPN](https://github.com/OpenVPN/openvpn) is the obvious choice. It is open source, and older versions work on 16.04 but [it does NOT work with the existing VPN built into Windows](https://serverfault.com/questions/830919/connect-to-openvpn-using-windows-10-built-in-vpn), so users would have to be able to install OpenVPN client on their PCs. While that may be possible, avoiding the requirement seems worthwhile. If Windows users will have to install something, they might as well install an [SFTP client](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#sftp). 

The Windows built-in VPN client supports only IKEv2, L2TP, PPTP and SSTP tunneling protocols.

IKEv2 was developed by M$ and Cisco and [isn't bad](https://www.cactusvpn.com/beginners-guide-to-vpn/what-is-ikev2/), it's difficult to [setup on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-16-04). While most OS's support connecting to an IKEv2 VPN, the setup is again difficult on non M$ OSs. 

L2TP/IPSec can probably be supported via [Openswan and xl2tpd](https://github.com/xelerance/Openswan/wiki/L2tp-ipsec-configuration-using-openswan-and-xl2tpd). Most tutorials assume that the Ubuntu server is public facing or will be accessed through a firewall. Some changes may be necessary for local access. 

PPTP is old, often disabled by routers, and inherently insecure, but since we are doing this on a local network with a client that is totally insecure anyway, who cares? It's [very easy to setup](https://bobcares.com/blog/install-pptp-server-ubuntu/), fast, and still supported by every client. This is probably the best bet for an initial setup.
 
SSTP is M$ proprietary and while there are services available for Ubuntu, it is not well support by clients other than Windows. 



#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-04-12 06:57](https://github.com/HaddingtonDynamics/Dexter/issues/80#issuecomment-612573304):

Tried the very easy setup from 
https://bobcares.com/blog/install-pptp-server-ubuntu/

Note: This requires that [Dexter be connected to the internet](Dexter-Networking#internet-access)

After [SSHing into Dexter](Dexter-Networking#shell-access-via-ssh):
1. `apt-get install pptpd`

2. Setup the local IP to use and the IP range to assign to clients when they connect.
`nano /etc/pptpd.conf ` then at the bottom of the file, set the IP addresses to match your network. Because I'm no a 192.168.0.x net, I used
````
# (Recommended)
localip 192.168.0.141
remoteip 192.168.0.234-238,192.168.0.245
````
But if you are on a 192.168.1.x network, just change the IP addresses to match. 

3. Next,
`nano /etc/ppp/pptpd-options` and set the ms_dns settings to use google:
````
# Network and Routing

# If pppd is acting as a server for Microsoft Windows clients, this
# option allows pppd to supply one or two DNS (Domain Name Server)
# addresses to the clients.  The first instance of this option
# specifies the primary DNS address; the second instance (if given)
# specifies the secondary DNS address.
# Attention! This information may not be taken into account by a Windows
# client. See KB311218 in Microsoft's knowledge base for more information.
ms-dns 8.8.8.8
ms-dns 8.8.4.4
````
4. Next, setup the user name and password. To avoid confusion, I just used the standard defaults for Dexter, but notice that if you want to specify a domain, you need to include that in front of the username. E.g. instead of "root" use "DEXTER\\root" if you tell windows you are connecting to a domain called "DEXTER"
`nano /etc/ppp/chap-secrets`
````
# Secrets for authentication using CHAP
# client        server  secret                  IP addresses
root    pptpd   klg     *
````
5. Enable forwarding between the internal and external IP addresses
`nano /etc/sysctl.conf` find the ip_forward line and uncomment it (remove the leading #)
````
# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1
````
6. Link the vpn clients out to the internet
`iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`
On this step I got this error:
`libkmod: ERROR ../libkmod/libkmod-config.c:635 kmod_config_parse: /etc/modprobe.d/pptpd.conf line 1: ignoring bad line starting with 'nf_nat_pptp'`
It may not be important:
https://bugs.launchpad.net/ubuntu/+source/pptpd/+bug/1571295
or can be worked around. 
7. start it
`/etc/init.d/pptpd restart`

`systemctl status pptpd` on Dexter shows any error messages. 

If you make any changes, do a 
`service pptpd restart`
to ensure they are incorporated. 

Next, setup your VPN connection from your PC. Be sure to specify "Point to Point Tunneling Protocal (PPTP)" as the type, but other than that, it's just the standard stuff. Here are instructions for [Windows 10](https://my.ibvpn.com/knowledgebase/267/Set-up-the-PPTP-on-Windows-10.html), [8](https://my.ibvpn.com/knowledgebase/73/Set-up-the-PPTP-VPN-on-Windows-8.html) [7](https://my.ibvpn.com/knowledgebase/42/set-up-the-pptp-vpn-connection-on-windows-7.html), 

When I first tried to connect from windows, after the status message "Registering your computer on the network" I was initially getting
`Error 734: The PPP link control protocol was terminated`

`systemctl status pptpd` on Dexter showed:
````
No CHAP secret found for authenticating
Peer DEXTER\\root failed CHAP authentication
````
I realized I had setup the VPN on windows to connect to a domain of "DEXTER" and a user of "root". That can be fixed by changing the chap-secrets file on Dexter:
`nano /etc/ppp/chap-secrets`
````
# Secrets for authentication using CHAP
# client        server  secret                  IP addresses
DEXTER\\root    pptpd   klg     *
````
or by specifying an empty domain on the Windows side. 

Once connected, you should have access to everything on Dexter via the SAMBA share, but this needs to be tested on a Windows 10 machine.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-05-18 20:49](https://github.com/HaddingtonDynamics/Dexter/issues/80#issuecomment-630427835):

Seems to work, closing until someone tells me otherwise.


-------------------------------------------------------------------------------

# [\#79 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/79) `closed`: SD Card Image

#### <img src="https://avatars1.githubusercontent.com/u/38500658?v=4" width="50">[topteamc](https://github.com/topteamc) opened issue at [2020-02-11 01:59](https://github.com/HaddingtonDynamics/Dexter/issues/79):

hi,
first i want to thanks every one participate in this awesome project.
can get the SD card image?
thanks again. 

#### <img src="https://avatars3.githubusercontent.com/u/5458696?v=4" width="50">[jonfurniss](https://github.com/jonfurniss) commented at [2020-02-11 17:32](https://github.com/HaddingtonDynamics/Dexter/issues/79#issuecomment-584756873):

Hello, here is a link to the most recent version of the Dexter HD image:
https://drive.google.com/open?id=1cT9Z0NyPovMRyLEJriLUFKsDkP9Zk0cy
The zipped file is about 2gb, so might take a while to download!
If you have any questions that need a quick response, feel free to join our Discord channel: https://discord.gg/ZWpeVve

#### <img src="https://avatars1.githubusercontent.com/u/38500658?v=4" width="50">[topteamc](https://github.com/topteamc) commented at [2020-02-11 19:04](https://github.com/HaddingtonDynamics/Dexter/issues/79#issuecomment-584798692):

thank you :*

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-02-11 20:07](https://github.com/HaddingtonDynamics/Dexter/issues/79#issuecomment-584826822):

Just FYI, more information on the SD card image is available here:
https://github.com/HaddingtonDynamics/Dexter/wiki/SD-Card-Image
and documentation on the setup of the image is included in #25


-------------------------------------------------------------------------------

# [\#78 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/78) `open`: Startup accuracy / true home

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-11-19 00:49](https://github.com/HaddingtonDynamics/Dexter/issues/78):

Although #5 is closed with the index pulses, and that allows us to always return to the same starting position, there are several issues that prevent that from being a true home; that position isn't actually the position that you defined as home during the calibration process.

- Because during movement joint calibration, there is a "frame dragging" of the sensor data behind the physical position of the joint. This is caused by the friction in the system, and results in us mapping the current motor position to a past encoder position.

- Also, no matter how hard you try, you can never really place the robot at true home with the human eye, because an error of 0.5 degree in Joint 2 (for example) can result in a 6 mm error at the end effector.

To solve this issue
, 
- We have implemented a SetParameter to offset the PID move command values and returned measured angles. 
https://github.com/HaddingtonDynamics/Dexter/commit/4c506d60a42ed31d4acc35f74e6f6262ac6a78e5#diff-a940a548ba41bc988f99d51fd02f21de

- We may need to build a physical rig to calibrate the robots at startup. 

- Measuring the transition from one eye to another may help.

Summary: Robot at apparent home, all angles near zero, but it is hard to accurately measure them physically. After calibration, you will be slightly off of home, but the sensors will all say zero. Offset angles if error can be measured.



#### <img src="https://avatars3.githubusercontent.com/u/4135305?v=4" width="50">[Jacob Turner](https://github.com/NinjaJake86) commented at [2020-08-05 20:16](https://github.com/HaddingtonDynamics/Dexter/issues/78#issuecomment-669479112):

Not looked at this but could the physical rig be built into the robot? Maybe add a small point on the base and on the toolend which lock together effectivly forcing the robot into a known position, it may not be the home position but if its a known position then you could calculate the movement required to reach home.

EDIT: This would remove the need for a whole physical rig just for the initial calibration


-------------------------------------------------------------------------------

# [\#77 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/77) `open`: Plugging in more than 1 USB device requires a USB hub.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-11-14 00:06](https://github.com/HaddingtonDynamics/Dexter/issues/77):

As soon as #64 was addressed, it became obvious that having multiple devices plugged in would be a very good idea. 

This USB hub seems to work well, can can be powered from our own internal +5 volt bus as needed:
https://www.adafruit.com/product/4115
Currently available here: (as of 2020/06/01)
https://www.amazon.com/Adafruit-4115-Zero4U-Port-Without/dp/B07PP91HWD/ref=sr_1_2

There is some concern that it may not be available in the future, but the basic footprint is for the RasPi  model Zero, so others will be available, e.g.
https://www.amazon.com/MakerSpot-Stackable-Raspberry-Connector-Bluetooth/dp/B01IT1TLFQ/ref=pd_cp_147_1/137-9153670-7027920

The placement of the USB ports and the input port may vary. 

For now, just strap tying it inside a skin or onto the center spar seems to work. The WiFi dongle ( #51 ) and Audio adapter / speakers ( #72 ) can perhaps be mounted with it.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-06 17:39](https://github.com/HaddingtonDynamics/Dexter/issues/77#issuecomment-595880287):

I've had problems with the above unit dropping off-line after extended on-time. It /may/ have shorted out to the carbon fiber strake it was mounted on, but I had a strip of cardboard behind it and that did not appear to be perforated, so I'm doubtful that was the issue. Will try again with plastic or rubber insulator.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-04-06 05:29](https://github.com/HaddingtonDynamics/Dexter/issues/77#issuecomment-609573186):

Also available from Mouser:
https://www.mouser.com/ProductDetail/485-4115
and Digikey (but at a higher price)
https://www.digikey.com/product-detail/en/adafruit-industries-llc/3298/1528-2083-ND/6834072


-------------------------------------------------------------------------------

# [\#76 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/76) `closed`: Job engine unable to read and write local files.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-11-04 19:18](https://github.com/HaddingtonDynamics/Dexter/issues/76):

To work around this, modify line 97 of /root/Documents/dde/core/index.js from:
`var {load_files, persistent_initialize, dde_init_dot_js_initialize} = require('./storage.js')`
to
`var {file_content, write_file, load_files, persistent_initialize, dde_init_dot_js_initialize} = require('./storage.js')`
and add lines after 125:
````
global.write_file = write_file
global.load_files = load_files
global.file_content = file_content
````

Note: The "job engine" (which is just DDE running on the robot under node.js instead of electron) is currently based on DDE 3.0.7. It will be updated at some point, after testing of all required scripts on the robot. When that happens, this issue should be amended to point to the update and closed. For now, issues can be patched on the existing code. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-25 19:42](https://github.com/HaddingtonDynamics/Dexter/issues/76#issuecomment-649779930):

This should be fixed already on the image used for HDI and later robots.


-------------------------------------------------------------------------------

# [\#75 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/75) `closed`: apt-get fails "Encountered a section with no Package: header"

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-11-01 00:18](https://github.com/HaddingtonDynamics/Dexter/issues/75):

https://askubuntu.com/questions/454895/update-manager-bug-encountered-a-section-with-no-package-header

The following two commands fix this. The first command will remove the damaged list and when you run the second command it will replace it with a new list.

`sudo rm /var/lib/apt/lists/* -vf`

`sudo apt-get update`




-------------------------------------------------------------------------------

# [\#74 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/74) `closed`: Incorrect ANGLE_END_RATIO between Joints 1-3 and Joints 4-5

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-10-11 01:05](https://github.com/HaddingtonDynamics/Dexter/issues/74):

Apparently an error was introduced into the AxisCal.txt file here a long time ago because the robot used to make this (Jame Newtons HD) has nonstandard pulleys on its Joint 4 and 5 axis motors. That was compensated for and then that got copied in here by mistake.  If any Dexter HD's are going to the wrong angle in open loop mode, this is probably why. Closed loop would compensate automatically but would start at a slightly incorrect angle.


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-10-11 01:05](https://github.com/HaddingtonDynamics/Dexter/issues/74#issuecomment-540857640):

Fixed in
https://github.com/HaddingtonDynamics/Dexter/commit/df5877e6bafecf9057a9eaa51c68ee6429dcf49d


-------------------------------------------------------------------------------

# [\#73 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/73) `closed`: Control of End Effector wires / IO incompatible with monitor / Dynamixel servos

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-09-26 00:04](https://github.com/HaddingtonDynamics/Dexter/issues/73):

At the wiki page:
https://github.com/HaddingtonDynamics/Dexter/wiki/End-Effectors#j20--j21-blue-and-green-wires
we documented the use of the <TT>w 64 _value_</TT> oplet to switch the blue and green wires at the end effector to other functions such as RC servo, PWM out, or generic IO. Address 65 and 66 could then be used to set the PWM duty, frequency, etc... 

However, access to the functions at address 64 (and 65, 66) were removed in 
https://github.com/HaddingtonDynamics/Dexter/commit/42df0e01285ef8b67764ed53f3cc697df44d4d93
when keyholeing was added to reduce the size of the FPGA address space, but that was probably not necessary since these are not keyholed, their address simply changed. Indirection from the old address (64-66) to the new address (31-33) can be supported via the `OldMemMapInderection` array. 

In https://github.com/HaddingtonDynamics/Dexter/commit/42df0e01285ef8b67764ed53f3cc697df44d4d93#diff-691272021fae98368efb598f8e089c16R285 we:

Re-enable IO control and "Gripper" items in 'w' oplet. Specifically addresses 
64: END_EFFECTOR_IO, 65: SERVO_SETPOINT_A, 66: SERVO_SETPOINT_B, 
73: GRIPPER_MOTOR_CONTROL, 74: GRIPPER_MOTOR_OFF_WIDTH, and 75: GRIPPER_MOTOR_ON_WIDTH 
should again be accessible via the w oplet. 

The complete DexRun.C file with these changes is available here:
https://github.com/HaddingtonDynamics/Dexter/blob/StepAngles/Firmware/DexRun.c
Note: this is on the StepAngles branch and requires an updated of the FPGA .bit file for compatibility:
https://github.com/HaddingtonDynamics/Dexter/tree/StepAngles/Gateware

This re-adding has not been completely tested, and the monitor mode may interfere with address 64 because it wants to get the status of the dynamixel servos and so re-enables them, overwriting whatever setup has been done there. For now, this can be avoid by starting with runMode of zero. E.g. `DexRun 1 3 0` in RunDexRun.

TODO: Find a way to avoid query of Dynamixels when address 64 is set for something else. 



#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-10-02 23:52](https://github.com/HaddingtonDynamics/Dexter/issues/73#issuecomment-537727858):

In https://github.com/HaddingtonDynamics/Dexter/commit/31c1e41f59eb86452bd60402ce426722c248e1ff we add `shadow_map` array which duplicates the values of the `mapped` array in standard RAM rather than in the FPGA shared map space. The RegExp search and replace function of VSCode was used to change every occurrence of `mapped\[(.*)\] ?=(.*)` into `mapped[$1]=shadow_map[$1]=$2`. e.g. `mapped[END_EFFECTOR_IO]=128+64+4;` becomes `mapped[END_EFFECTOR_IO]=shadow_map[END_EFFECTOR_IO]=128+64+4;`

The end result is that we can now read back the last known setting of any mapped address. In https://github.com/HaddingtonDynamics/Dexter/commit/9718c9e49224d4deeaacba39f92bc7cb9f036759 we test that shadow_map[END_EFFECTOR_IO] to see if it's been set for the Dynamixels, and if not, we don't query them for their position in the monitor thread. 

This appears to work and should close this issue. Further testing in other IO modes should probably get done at some point.

#### <img src="https://avatars0.githubusercontent.com/u/22947085?v=4" width="50">[Kent Gilson](https://github.com/kgallspark) commented at [2019-10-03 01:03](https://github.com/HaddingtonDynamics/Dexter/issues/73#issuecomment-537742609):

Sounds good. We will test over the next couple of daysOn Oct 2, 2019 4:52 PM, JamesNewton <notifications@github.com> wrote:Closed #73.

—You are receiving this because you are subscribed to this thread.Reply to this email directly, view it on GitHub, or mute the thread.


-------------------------------------------------------------------------------

# [\#72 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/72) `open`: Need USB audio adapter to speak / listen

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-09-05 18:54](https://github.com/HaddingtonDynamics/Dexter/issues/72):

Since there is no actual connection to audio on the MicroZed board, an external USB audio adapter is probably the best way to help Dexter find it's voice... and possibly it's ears. 

This device was tested:
https://www.amazon.com/dp/B01J7P0OGI  as it's known to work with Linux without extra drivers, and supports the RasPi, which is our closest popular neighbor. It's also nice that it has an external volume control and mutes for speaker and mic (incase anyone worries about robots listening...) 

EDIT: This all-in-one USB sound adapter, amplifier and speakers also works, the only disadvantage being that there is no physical volume control (see notes on amixer below):
https://www.amazon.com/HONKYOB-Speaker-Computer-Multimedia-Notebook/dp/B075M7FHM1/ref=asc_df_B075M7FHM1/? $11.99
https://www.adafruit.com/product/3369 $12

After connecting, the light on the USB adapter comes on and a quick look at `ls /dev/*audio*` shows `/dev/audio1` so we have a device installed!

Of course, nothing is that easy (except USB 2 to HDMI adapters, and keyboards) so when we try `speaker-test` we get: `ALSA lib confmisc.c:768:(parse_card) cannot find card '0'` which makes sense as the device was audio1 (not zero) and `aplay -l` had returned:
````
**** List of PLAYBACK Hardware Devices ****
card 1: Device [USB PnP Audio Device], device 0: USB Audio [USB Audio]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
````

Some googling found:
http://forums.debian.net/viewtopic.php?f=7&t=53516
and a quick edit of /etc/modprobe.d/alsa-base.conf to change the last line from:
`options snd-usb-audio index=-2`
to 
`options snd-usb-audio index=0`
then a restart, seems to have fixed the issue. speaker-test is able to produce pink noise and sine waves.

DDE core (Job Engine) doesn't seem to know what `speak` is:
But this is probably just an issue with the imports as with other libraries.

Sadly, the full DDE, (electron app) running on Dexter (via XWindows) doesn't seem to have any voices available. `window.speechSynthesis.getVoices()` returns an empty array.

`beep()` does work from electron, but again, "beep is not defined" in the Job Engine.

So the hardware is working, but effort is needed in the software area. 



#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-09-05 19:47](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-528550575):

It appears Electron has some issues with speech on Linux. 
https://github.com/noffle/electron-speech/issues/9
Our friend Bret may know something about it. It looks like they are using Google for speech output after all. I had hoped it was being done locally.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-09-05 23:07](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-528640585):

There are onboard TTS packages for Linux, including the old standard Festival and Pico TTS. 

Pico is quite impressive:
https://soundcloud.com/nerduno/sample-pico-tts-recording
and has been ported for the RasPi, which is close to our platform. 
https://github.com/mfurquim/picopi
Sadly it must be built from source, as the apt-get failed. Not sure it's worth the time. Also, it really wants to write to a .wav file instead of just streaming sound, but there may be away around that:
https://unix.stackexchange.com/questions/325019/pipe-output-from-program-which-only-outputs-to-a-file/325020#325020

I was able to install espeak, `apt-get install espeak` and it only took up 204K on the SD card. `espeak "Hello"` produces a robotic, but recognizable output along with a ton of warning / error messages which seem to be about accessing other audio systems. Despite the warnings / errors it works: The sound comes out.

"say" is also available, `apt-get install gnustep-gui-runtime` but takes 11MB on the drive, so I held off. 

And there are node packages for Festival at least:
https://github.com/Marak/say.js

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-09-09 22:04](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-529685487):

To make aplay work by defaut, e.g. without specifying the card, 
https://stackoverflow.com/questions/39552522/raspberry-pi-aplay-default-sound-card
`nano ~/.asoundrc`
to:
````
pcm.!default {
#        type hw
#        card 0
# on Dexter, we want the default device to be a plug into the hardware
        type plug
        slave {
                pcm "hw:0,0"
        }
}

ctl.!default {
        type hw
        card 0
}
````

This allows `espeak "hello" --stdout | aplay` which avoids all the warning messages that `espeak "hello"` wants to return (still not sure why all those are listed). 

Moving speak into dde_init doesn't work because `exec` needs `const {exec] = require('child_process')` and that generates "require is not defined". I /think/ that happens because dde_init is not in the node module folder? So next step is to try moving it into the code folder as speak.js or something?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-09-10 01:40](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-529731676):

To get the job engine working, we needed to add a special version of "speak" to the core/out.js file just before the requires at the end:
````

function speak({speak_data = "hello", volume = 1.0, rate = 1.0, pitch = 1.0, lang = "en_US", callback = null}) {
    //var text = stringify_for_speak(speak_data)
    //msg.text   = text
    //msg.volume = volume; // 0 to 1
    //msg.rate   = rate;   // 0.1 to 10
    //msg.pitch  = pitch;  // 0 to 2
    //msg.lang   = lang;
    //msg.onend  = callback
    exec("espeak \"" + speak_data + "\" -a "+ (volume*200) + " -p " + (pitch * 50) + " -s " + (rate * 37 + 130) );
    return speak_data
    }

module.exports.speak = speak
````

And then in index.js, near the end, we had to import speak from out.js (along with out)
````
var {out, speak} = require("./out.js")
````
and make it a global.
````
global.speak = speak
````

Now we can do 
`function(){speak({speak_data:"Now moving really really fast", rate:5, volume:0.5, pitch:2})},`
in a .dde job.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-09-10 21:24](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-530126695):

A more advanced version of speak that is in post dde 3.4.6 releases
and also works on DDE is:
````
function speak({speak_data = "hello", volume = 1.0, rate = 1.0, pitch = 1.0, lang = "en_US", voice = 0, callback = null} = {}){
    if (arguments.length > 0){
        var speak_data = arguments[0] //, volume = 1.0, rate = 1.0, pitch = 1.0, lang = "en_US", voice = 0, callback = null
    }
    var text = stringify_for_speak(speak_data)
    if(window.platform == "node"){
        exec("espeak \"" + speak_data + "\" -a "+ (volume*200) + " -p " + (pitch * 50) + " -s " + (rate * 37 + 130),
             callback );//this callback takes 2 args, an err object and a string of the shell output
                        //of calling the command.
    }
    else {
        var msg = new SpeechSynthesisUtterance();
        //var voices = window.speechSynthesis.getVoices();
        //msg.voice = voices[10]; // Note: some voices don't support altering params
        //msg.voiceURI = 'native';
        msg.text   = text
        msg.volume = volume; // 0 to 1
        msg.rate   = rate;   // 0.1 to 10
        msg.pitch  = pitch;  // 0 to 2
        msg.lang   = lang;
        var voices = window.speechSynthesis.getVoices();
        msg.voice  = voices[voice]; // voice is just an index into the voices array, 0 thru 3
        msg.onend  = callback //this callback takes 1 arg, an event.
        speechSynthesis.speak(msg);
        }
    return speak_data
}
````
This version also requires the definition of 
````
function stringify_for_speak(value, recursing=false){
    var result
    if ((typeof(value) == "object") && (value !== null) && value.hasOwnProperty("speak_data")){
        if (recursing) {
            dde_error('speak passed an invalid argument that is a literal object<br/>' +
                'that has a property of "speak_data" (normally valid)<br/>' +
                'but whose value itself is a literal object with a "speak_data" property<br/>' +
                'which can cause infinite recursion.')
        }
        else { return stringify_for_speak(value.speak_data, true) }
    }
    else if (typeof(value) == "string") { result = value }
    else if (value === undefined)       { result = "undefined" }
    else if (value instanceof Date){
        var mon   = value.getMonth()
        var day   = value.getDate()
        var year  = value.getFullYear()
        var hours = value.getHours()
        var mins  = value.getMinutes()
        if (mins == 0) { mins = "oclock, exactly" }
        else if(mins < 10) { mins = "oh " + mins }
        result    = month_names[mon] + ", " + day + ", " + year + ", " + hours + ", " + mins
        //don't say seconds because this is speech after all.
    }
    else if (Array.isArray(value)){
        result = ""
        for (var elt of value){
            result += stringify_for_speak(elt) + ", "
        }
    }
    else {
        result = JSON.stringify(value, null, 2)
        if (result == undefined){ //as happens at least for functions
            result = value.toString()
        }
    }
    return result
}
````
and 
````
window.month_names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September','October', 'November', 'December']
````
for speaking dates.

All of the above (except for the month_names) is in the post DDE 3.4.6 version of core/out.js

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-11-13 22:39](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-553637558):

We can control the volume of the audio output in software with the amixer command:
````
root@localhost:~# amixer
Simple mixer control 'PCM',0
  Capabilities: pvolume pvolume-joined pswitch pswitch-joined
  Playback channels: Mono
  Limits: Playback 0 - 255
  Mono: Playback 255 [100%] [-127.00dB] [on]
root@localhost:~# amixer scontrols
Simple mixer control 'PCM',0
root@localhost:~# amixer set 'PCM' 80%
Simple mixer control 'PCM',0
  Capabilities: pvolume pvolume-joined pswitch pswitch-joined
  Playback channels: Mono
  Limits: Playback 0 - 255
  Mono: Playback 204 [80%] [-127.20dB] [on]
root@localhost:~#

````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-11-14 20:55](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-554075374):

One issue with this code is that you can end up with multiple child processes running all saying things at the same time, instead of one after the next. To avoid that, a que or stack can be added:

````
var to_speak = []
function speak({speak_data = "hello", volume = 1.0, rate = 1.0, pitch = 1.0, lang = "en_US", callback = null}) {
    //var text = stringify_for_speak(speak_data)
    //msg.text   = text
    //msg.volume = volume; // 0 to 1
    //msg.rate   = rate;   // 0.1 to 10
    //msg.pitch  = pitch;  // 0 to 2
    //msg.lang   = lang;
    //msg.onend  = callback
    if (speak_data != null) { //new speech text
      let speak_cmd = "espeak \"" + speak_data + "\" -a "+ (volume*200) + " -p " + (pitch * 50) + " -s " + (rate * 37 + 130)
      to_speak.push(speak_cmd)
      }
    else { //finished speaking prior text
      if (to_speak.length > 0) {
        exec(to_speak[0], function(){ to_speak.shift(); speak({speak_data:null}); })
        }
      }
    if (to_speak.length == 1) {
      exec(to_speak[0], function(){ to_speak.shift(); speak({speak_data:null}); })
      }
    return speak_data
    }
````

Note: This code is missing the improvements made by Fry to handle different data types, and will only correctly speak strings, and will not work on PC DDE as it doesn't check what platform it's running on.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-11 17:43](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-597773296):

To make it easy to get Dexter to talk, and avoid any possible problems if there is no audio adapter available, use a script that checks that everything is ok. It's easy to a script create after [SSHing into Dexter](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#shell-access-via-ssh) using the nano editor:
````
cd /srv/samba/share
nano say
````
and then copy in the code below. In most terminal programs, paste works by right clicking. 
save the file by pressing Ctrl+w and answering "Y"

````
#!/bin/sh
if [ -c /dev/audio ]; then
        espeak "$@" --stdout | aplay
else
        echo no audio adapter found
fi
````
To make the script executable, chmod it:
````
chmod +x say-ip.sh
````
and then you can run it by typing:
````
./say-ip.sh
````

To have Dexter speak it's IP address, a script can be created as follows:
````
#!/bin/sh
./say 'Dexter is at I P. address'
hostname -I | sed 's/ \([^\n]\)/, or, \1/g' | ./say
````
You might call that file 'say-ip' and don't forget to `chmod +x say-ip` then call it with `./say-ip`

This could be added to the end of the RunDexRun startup script.

WARNING: Be very careful about adding any attempt to speak or play any sound to a script that needs to run on startup. If you don't have a sound card plugged in, that will generate an error, and the error may make the script file. E.g. adding those commands to speak the IP address to RunDexRun then unplugging the adapter will cause the robot to fail to start the DexRun firmware, etc... This issue can be avoided by using a bash script called that checks to verify the audio device is connected.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2020-03-11 17:47](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-597775402):

Having this at the end of RunDexRun is a great idea.
Requires no learning or other UI.
Let's you know your audio is working
AND gives you useful information.
If there was an easy way for a user to
get it to repeat that info, telling them how
in the speech would be great.


On Wed, Mar 11, 2020 at 1:43 PM JamesNewton <notifications@github.com>
wrote:

> To have Dexter speak it's IP address, a script can be created as follows:
>
> espeak "Dexter is at I P. address " --stdout | aplay
> hostname -I | sed 's/ \([^\n]\)/, or, \1/g' | espeak --stdout | aplay
>
> that can be called e.g. say-ip.sh and is easy to create after SSHing into
> Dexter via the nano editor:
>
> cd /srv/samba/share
> nano say-ip.sh
>
> and then copy in the above. In most terminal programs, paste works by
> right clicking.
> save the file by pressing Ctrl+w and answering "Y"
>
> To make the script executable, chmod it:
>
> chmod +x say-ip.sh
>
> and then you can run it by typing:
>
> ./say-ip.sh
>
> and it can be added to the end of the RunDexRun startup script.
>
> —
> You are receiving this because you were assigned.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-597773296>,
> or unsubscribe
> <https://github.com/notifications/unsubscribe-auth/AAJBG7JW7PHRLYDJR2QHJLLRG7ETNANCNFSM4IUBJW5Q>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-11 18:04](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-597784466):

If (and only if) the audio output device becomes a standard feature on Dexter, THEN... PHUI and other scripts could be updated to support triggering that output. e.g. one of the slots in PHUI could be the "read out your IP address" slot. Probably best if it were the "exit PHUI" slot so that DDE could actually connect after reading it out.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-05-26 22:25](https://github.com/HaddingtonDynamics/Dexter/issues/72#issuecomment-634313101):

P.S. Bitshift Variations in C-minor works from the Dexter command line if you have this setup:
https://github.com/JamesNewton/BitShift-Variations-unrolled


-------------------------------------------------------------------------------

# [\#71 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/71) `open`: Finding Dexters IP address
**Labels**: `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-08-28 23:57](https://github.com/HaddingtonDynamics/Dexter/issues/71):

Dexters ship with a pair of fixed IP addresses: 192.168.0.142 and 192.168.1.142. DHCP is disabled, on the CAT 5 adapter. This is probably best for direct connection to a PC, because then you can setup the PC CAT5 for one of those subnets, and always find Dexter. However, if you need multiple Dexters on a network, or want it accessible from multiple machines, then the network setup will have to be changed to move to DHCP. 

If a WiFI adapter is plugged into the USB connector under the CAT5 (well... it will melt, but if you plug in a USB A to A extension, and THEN plug in a WiFi adapter) and configure your routers SSID and password, it will be assigned an IP via DHCP. 

Once the IP has been assigned via DHCP, the address of Dexter is effectively unknown. So how can we find Dexters IP address(es)? 

1. Display. If Dexter had a screen, it could show the IP address. #24 documents work on a new end effector that would include a "tinyscreen". #44 documents the possible use of the console, microUSB connector on the MicroZed board with a PC or tablet (or even cell phone) to provide a powerful local user interface (`hostname -I` shows IP addresses). An actual display adapter would be even nicer. 

2. Boot dance. The robot currently attempts to "dance" out it's IP address on startup via moving joint 4/5. This is hard to catch and only shows one IP. 

3. MAC address / ARP. Address Resolution Protocol maps MAC addresses to IP address. Since Dexters CAT5 adapter is implemented in the FGPA, it does NOT have a "unique" assigned MAC address like most ethernet devices. This causes problems when multiple Dexters are on the same net, so the latest RunDexRun file looks for a robot serial number in the Defaults.make_ins file and updates the hwaddress line in the /etc/network/interfaces file with that value. After a restart, the MAC address will have been generated via the serial number and is far more likely to be unique. It uses the Xilinx mfgr code at the start of the MAC to avoid possible collisions with other mfgrs devices, as is recommended by Xilinx. As a result, any device with Xilinx mfg code on the net is likely to be a Dexter. 

In windows, at the command prompt, this will show you matching entries in the list of devices known to that PC:
`arp -a | find "00-5d-03"`

This assumes the Dexter has communicated once to the PC, and may not be present until after that communication has happened, which probably makes it less than totally useful except when directly connected: At that point, the PC is sure to see Dexters first connection and call for an IP address. 

Of these the first seems best. A display / local user interface is useful on it's own. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-09-10 01:30](https://github.com/HaddingtonDynamics/Dexter/issues/71#issuecomment-529729711):

Given an audio output #72 , and a TTS engine as described there, it should be possible to speak Dexters ip address when it changes via e.g.
`hostname -I | espeak --stdout | aplay`
or to remove the hard coded IP addresses:
`hostname -I | sed 's/192\.168\.[0|1]\.142//g' | espeak --stdout | aplay`

This seems simple:
https://askubuntu.com/questions/1005653/how-do-i-execute-a-script-after-dhcp-assigns-an-ip-address-on-start-up
List of the available state changes:
http://manpages.ubuntu.com/manpages/bionic/man8/dhclient-script.8.html

However, that doesn't seem to actually work. E.g. when you connect or disconnect the WiFi, the script is not fired.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-28 00:36](https://github.com/HaddingtonDynamics/Dexter/issues/71#issuecomment-605368321):

WARNING: Be very careful about adding any attempt to speak or play any sound to a script that needs to run on startup. If you don't have a sound card plugged in, that will generate an error, and the error may make the script file. E.g. adding those commands to speak the IP address to RunDexRun then unplugging the adapter will cause the robot to fail to start the DexRun firmware, etc... 

This issue can be avoided by using a bash script called that checks to verify the audio device is connected. 

````
#!/bin/sh

if [ -c /dev/audio ]; then
        espeak "$@" --stdout | aplay
else
        echo no audio adapter found
fi

````

You might call that file 'say' and don't forget to `chmod +x say` then call it with `./say "hello all!"`

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-26 00:14](https://github.com/HaddingtonDynamics/Dexter/issues/71#issuecomment-649878912):

#83 Bonjour may be a useful tool in Windows 10 and MACs.


-------------------------------------------------------------------------------

# [\#70 PR](https://github.com/HaddingtonDynamics/Dexter/pull/70) `closed`: Speeds update

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-07-23 21:13](https://github.com/HaddingtonDynamics/Dexter/pull/70):

The speeds updates are working, the code appears to be stable and it's time to merge. 




-------------------------------------------------------------------------------

# [\#69 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/69) `closed`: Add a way to erase files on Dexter's file system

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-07-22 21:00](https://github.com/HaddingtonDynamics/Dexter/issues/69):

With the new errors.log (related to the monitor mode) we really need a way to delete files on the robot. Although we could use another oplet (e.g. 'e' for 'e'rase is available) it seems like there is a lot of overlap on the 'W' or write_to_robot oplet. We can add a sub oplet for the 'W' oplet, but 'e' is already "end". We could use 'd'. e.g. `W 0 d /srv/samba/share/errors.log;`

It would also be good if it were a two step process to reduce the possibility of bad packets (remember, our socket system doesn't guarantee correct delivery) accidentally deleting a file. We could use the 'f' suboplet of the 'W' command to first open the file, then make the 'd' suboplet delete the currently open file. e.g. `W 0 f \srv\samba\share\errors.log;` and then `W d` The trick with that is Linux doesn't have a way to delete a file by handle. You can only [`int unlink(const char *pathname);`](https://linux.die.net/man/2/unlink) There is a sort of hacky trick to get the pathname back from the file id:
https://stackoverflow.com/a/1189582/663416

Another way of adding safety is to require a checksum of the path. For consistency, the W oplet requires a number after the suboplet but before the filename. We could do a [Fletcher 16](https://en.wikipedia.org/wiki/Fletcher%27s_checksum) on the path and send that with the W command. E.g. `W d 63301 /srv/samba/share/errors.log` would work because that F16 sum of "/srv/samba/share/errors.log" is correct. This seems like it would be good enough. 

This also allows deleting (empty) folders if we use [`int remove(const char *pathname);`](https://linux.die.net/man/2/rmdir) instead of unlink.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-24 02:29](https://github.com/HaddingtonDynamics/Dexter/issues/69#issuecomment-514454165):

Or we could just do this via #20

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-21 19:10](https://github.com/HaddingtonDynamics/Dexter/issues/69#issuecomment-523608014):

Use #20


-------------------------------------------------------------------------------

# [\#68 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/68) `closed`: Check Firmware against Gateware version on startup

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-07-20 02:07](https://github.com/HaddingtonDynamics/Dexter/issues/68):

See:
https://github.com/HaddingtonDynamics/Dexter/wiki/read-from-robot#read-from-fpga-memory

for how to implement a check by the DexRun.c program to verify that the INPUT_OFFSET define matches the number of input parameters in the FPGA. If they don't match, instead of crashing, DexRun can set the DexError code number to something DDE can recognize that there is a firmware vs gateware mismatch. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-21 19:15](https://github.com/HaddingtonDynamics/Dexter/issues/68#issuecomment-523609850):

Implemented in 
https://github.com/HaddingtonDynamics/Dexter/commit/ce61cf652dc591dab8ba1096834206f7c551ce72#diff-691272021fae98368efb598f8e089c16


-------------------------------------------------------------------------------

# [\#67 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/67) `closed`: Bootup time increased when node.js was installed

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-07-11 01:19](https://github.com/HaddingtonDynamics/Dexter/issues/67):

For some reason, when node.js / NVM was installed, the time it takes the OS to boot increased by something like 30 to 90 seconds. No idea why. Very little has been written about this, but it might be this issue:

https://www.growingwiththeweb.com/2018/01/slow-nvm-init.html


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-28 00:21](https://github.com/HaddingtonDynamics/Dexter/issues/67#issuecomment-525532643):

I did some testing on my current image, from power up to boot dance finish:

- No network connections at all: 52 seconds. There is about a 5 second pause where it waits on the adapter and a 25 second pause where it tries to bring up the network. Neither of those appear to have anything to do with node, which is very interesting to me as I could have sworn that boot delay started when I added that... 

- CAT 5 to PC, but no internet available: 45 seconds. 20 seconds waiting for the network. This is what you are probably seeing. 

- CAT 5 to router to internet: 31 seconds flat, no noticeable pauses. 

- CAT 5 to router to internet, AND WiFI dongle. Same 31 seconds. 

- Not CAT 5, but WiFi dongle. 53 seconds. I'm sad about that. I'd hoped that the WiFi would avoid a network wait, but apparently not. 

I have noticed there is a 1 to 10 second delay where it tries to mount the SD card as ext3 and then ext2 before "recovering" it and mounting it as ext4. The time delay seems quite random. It's usually just a second or two, but I've seen it sit there for a while. I've spent several hours investigating that and I'll be darned if I can tell you any more about it now than I could before lunch. That stuff is buried. 

I've spent another hour trying to avoid it waiting for the network. I've edited the:
/lib/systemd/system/NetworkManager-wait-online.service
file to change the timeout to 5 seconds. Which make NO difference at all. 

However, I noticed the actual message is about "raise network" which lead me to this
https://askubuntu.com/questions/862176/how-to-fix-a-start-job-is-running-for-the-raise-network-in-ubuntu-server-16/1061852  
which I tried and it again, makes zero difference. 

I've taken those changes back out just to ensure it's not going to cause problems in the future. 

There is always one failure message, for a braille support device:
http://manpages.ubuntu.com/manpages/bionic/man1/brltty.1.html  
Dexter is not friendly to the blind apparently... But it takes no time.

Long story only slightly longer: If you are seeing boot times of longer than a minute, please try the newest image and do the USB cable connection, watch it boot, and tell me what it's sitting on:
https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-USB-Connection  

Best advice: Live with one minute boot, or connect to router. 

Closing this as there is no evidence that it's actually caused by node.


-------------------------------------------------------------------------------

# [\#66 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/66) `closed`: #EyeNumbers for joints 3 and 5 swapped

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-05-29 04:25](https://github.com/HaddingtonDynamics/Dexter/issues/66):

When using the read from robot oplet to get the "#EyeNumbers" keyword, the 3rd value returned is the eye number for joint 5 and the 5th is for joint 3. 
https://github.com/HaddingtonDynamics/Dexter/wiki/read-from-robot

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-05-29 16:21](https://github.com/HaddingtonDynamics/Dexter/issues/66#issuecomment-497008203):

Fixed in https://github.com/HaddingtonDynamics/Dexter/commit/b3c9a7dfb5f310dc27d4b254d26a80abda0bacf1


-------------------------------------------------------------------------------

# [\#65 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/65) `closed`: Pictures

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-05-14 04:13](https://github.com/HaddingtonDynamics/Dexter/issues/65):

Just a fake issue to make it easy to add pictures to the Wiki.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-05-14 04:14](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-492071936):

![GripperTickMarkPositionToLoadTool_1](https://user-images.githubusercontent.com/419392/57670424-18b3ff00-75c4-11e9-9521-967dbbd6b59b.JPG)
![GripperTickMarkPositionToLoadFinger_1](https://user-images.githubusercontent.com/419392/57670426-1baeef80-75c4-11e9-8f35-2c820016c5ce.JPG)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-05-15 03:13](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-492487219):

![DexterFPGA_Overview](https://user-images.githubusercontent.com/419392/57746151-be2ea780-7684-11e9-80b5-95490f015973.png)

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-05-16 09:09](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-492985427):

Transparent
![icon](https://user-images.githubusercontent.com/28599280/57841521-489a1700-77fd-11e9-959b-8defaa382436.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-05-28 23:56](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-496732457):

![image](https://user-images.githubusercontent.com/419392/58519674-779f7980-8169-11e9-9146-c67a6d174f35.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-04 01:20](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-498482753):

Picture of clamping Dexter base to a table

![image](https://user-images.githubusercontent.com/419392/58844223-183edf00-862b-11e9-8197-37fc97029a21.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-04 01:24](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-498483431):

Screwing a Dexter to the table
![image](https://user-images.githubusercontent.com/419392/58844593-c5febd80-862c-11e9-9076-bd438fcaf95d.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-04 01:26](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-498483868):

Hot gluing Dexter to a table
![image](https://user-images.githubusercontent.com/419392/58844667-183fde80-862d-11e9-8bcc-aeaed5865306.png)

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-06-04 15:29](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-498722017):

Crystal clear picture of screwing!
For the hot glue, how about a picture with
one hole filled with glue and the glue gun poised to
squirt in glue to the 2nd (as yet unfilled).
It would be really good if the color of the glue
was not the same color as a foot.

Most pictures in most "assembly manuals"
are so low res as to be pretty ambiguous as
to what you really need to do.
This aren't!


On Mon, Jun 3, 2019 at 9:26 PM JamesNewton <notifications@github.com> wrote:

> Hot gluing Dexter to a table
> [image: image]
> <https://user-images.githubusercontent.com/419392/58844667-183fde80-862d-11e9-8bcc-aeaed5865306.png>
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/65?email_source=notifications&email_token=AAJBG7KZ3THIHISH2YKE54LPYXAEXA5CNFSM4HMVTUAKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODW3EFHA#issuecomment-498483868>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/AAJBG7OWNWFH44KJZE6RWRDPYXAEXANCNFSM4HMVTUAA>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-05 00:51](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-498896303):

Hotglue in a foot
![image](https://user-images.githubusercontent.com/419392/58922776-4dae0000-86f1-11e9-9b93-85de3b98551f.png)

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-06-05 03:13](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-498922885):

In the screwing picture, there are only 2 holes in a foot.
Here it looks like there's 4, but in any case
this new black and white picture is confusing,
much more so than the color screwing picture.

On Tue, Jun 4, 2019 at 8:51 PM JamesNewton <notifications@github.com> wrote:

> Hotglue in a foot
> [image: image]
> <https://user-images.githubusercontent.com/419392/58922776-4dae0000-86f1-11e9-9b93-85de3b98551f.png>
>
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/65?email_source=notifications&email_token=AAJBG7L32C3EDSN3NLXEJGTPY4EYJA5CNFSM4HMVTUAKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODW6I3LY#issuecomment-498896303>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/AAJBG7PFK47KMET35ZHCZWLPY4EYJANCNFSM4HMVTUAA>
> .
>

#### <img src="https://avatars3.githubusercontent.com/u/5458696?v=4" width="50">[jonfurniss](https://github.com/jonfurniss) commented at [2019-06-05 15:13](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-499126800):

There are two holes for screwing into on the top of the robot foot.
There are four indents underneath the foot that can be filled with glue to
use for additional traction.
While the two holes for screwing line up with the front two glue indents,
the two features are for different purposes and not related.

On Tue, Jun 4, 2019 at 8:13 PM cfry <notifications@github.com> wrote:

> In the screwing picture, there are only 2 holes in a foot.
> Here it looks like there's 4, but in any case
> this new black and white picture is confusing,
> much more so than the color screwing picture.
>
> On Tue, Jun 4, 2019 at 8:51 PM JamesNewton <notifications@github.com>
> wrote:
>
> > Hotglue in a foot
> > [image: image]
> > <
> https://user-images.githubusercontent.com/419392/58922776-4dae0000-86f1-11e9-9b93-85de3b98551f.png
> >
> >
> > —
> > You are receiving this because you commented.
> > Reply to this email directly, view it on GitHub
> > <
> https://github.com/HaddingtonDynamics/Dexter/issues/65?email_source=notifications&email_token=AAJBG7L32C3EDSN3NLXEJGTPY4EYJA5CNFSM4HMVTUAKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODW6I3LY#issuecomment-498896303
> >,
> > or mute the thread
> > <
> https://github.com/notifications/unsubscribe-auth/AAJBG7PFK47KMET35ZHCZWLPY4EYJANCNFSM4HMVTUAA
> >
> > .
> >
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/65?email_source=notifications&email_token=ABJUWCHFZ3SDLI5EK7LXZB3PY4VORA5CNFSM4HMVTUAKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODW6PLBI#issuecomment-498922885>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABJUWCH34BDBH5MO74NMTVTPY4VORANCNFSM4HMVTUAA>
> .
>

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-06-05 20:37](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-499245612):

Thanks. Now the challenge is to take a picture that
let's you know you're even looking at the bottom of a foot.
Also, I am guessing that you have to
dab glue onto 2 or 3 feet at once then
plunk the whole robot firmly on the table.


On Wed, Jun 5, 2019 at 11:13 AM jonfurniss <notifications@github.com> wrote:

> There are two holes for screwing into on the top of the robot foot.
> There are four indents underneath the foot that can be filled with glue to
> use for additional traction.
> While the two holes for screwing line up with the front two glue indents,
> the two features are for different purposes and not related.
>
> On Tue, Jun 4, 2019 at 8:13 PM cfry <notifications@github.com> wrote:
>
> > In the screwing picture, there are only 2 holes in a foot.
> > Here it looks like there's 4, but in any case
> > this new black and white picture is confusing,
> > much more so than the color screwing picture.
> >
> > On Tue, Jun 4, 2019 at 8:51 PM JamesNewton <notifications@github.com>
> > wrote:
> >
> > > Hotglue in a foot
> > > [image: image]
> > > <
> >
> https://user-images.githubusercontent.com/419392/58922776-4dae0000-86f1-11e9-9b93-85de3b98551f.png
> > >
> > >
> > > —
> > > You are receiving this because you commented.
> > > Reply to this email directly, view it on GitHub
> > > <
> >
> https://github.com/HaddingtonDynamics/Dexter/issues/65?email_source=notifications&email_token=AAJBG7L32C3EDSN3NLXEJGTPY4EYJA5CNFSM4HMVTUAKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODW6I3LY#issuecomment-498896303
> > >,
> > > or mute the thread
> > > <
> >
> https://github.com/notifications/unsubscribe-auth/AAJBG7PFK47KMET35ZHCZWLPY4EYJANCNFSM4HMVTUAA
> > >
> > > .
> > >
> >
> > —
> > You are receiving this because you are subscribed to this thread.
> > Reply to this email directly, view it on GitHub
> > <
> https://github.com/HaddingtonDynamics/Dexter/issues/65?email_source=notifications&email_token=ABJUWCHFZ3SDLI5EK7LXZB3PY4VORA5CNFSM4HMVTUAKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODW6PLBI#issuecomment-498922885
> >,
> > or mute the thread
> > <
> https://github.com/notifications/unsubscribe-auth/ABJUWCH34BDBH5MO74NMTVTPY4VORANCNFSM4HMVTUAA
> >
> > .
> >
>
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/65?email_source=notifications&email_token=AAJBG7KSJVKYN4F2YE5UM6LPY7J3NA5CNFSM4HMVTUAKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODXABEEA#issuecomment-499126800>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/AAJBG7LP5FHVCLS45NNQKZ3PY7J3NANCNFSM4HMVTUAA>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-13 18:48](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-501833345):

Image of shipping case with first layer / base
![image](https://user-images.githubusercontent.com/419392/59459216-1c0ff580-8dd1-11e9-8ece-7ac85a8863e8.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-13 22:02](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-501895201):

Where to grab Dexter out of the packing case.
![image](https://user-images.githubusercontent.com/419392/59470338-36a39800-8dec-11e9-8b33-f0f3ae1827b8.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-13 22:39](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-501903919):


Correct jumper settings on MicroZed board
![image](https://user-images.githubusercontent.com/419392/82377855-240ce800-99d9-11ea-8f70-4ef9e290648f.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-18 20:02](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-503289600):

Bad encoder eye. LED pulled out of encoder block.
![image](https://user-images.githubusercontent.com/419392/59715702-4f83c300-91c9-11e9-85df-87ec6569a9de.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-18 20:10](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-503292440):

Good encoder, after replacing LED in hole of encoder block.
![image](https://user-images.githubusercontent.com/419392/59716213-6d9df300-91ca-11e9-87d6-0b530f39fb61.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-06-18 20:14](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-503293853):

LED or Photo sensor pulled out of hole in encoder block
![image](https://user-images.githubusercontent.com/419392/59716415-cff6f380-91ca-11e9-94e7-980a95b79e56.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-10-25 00:26](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-546152176):

This is what you should see on the console after installing a WiFi adapter. Note that it does not have an IP address, but it is shown in the list of adapters, after eth0 and lo. 
![image](https://user-images.githubusercontent.com/419392/67534526-56dd4080-f683-11e9-87b8-1a84c22a2c8d.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-10-25 00:30](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-546152801):

Opening screen of `nmtui`
![image](https://user-images.githubusercontent.com/419392/67534650-f39fde00-f683-11e9-8946-5ddc322f6b61.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-10-25 00:33](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-546153368):

Select Activate a connection in `nmtui`
![image](https://user-images.githubusercontent.com/419392/67534741-64df9100-f684-11e9-8679-df477c2321a2.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-10-25 00:35](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-546153712):

Selecting an SSID in `nmtui`
![image](https://user-images.githubusercontent.com/419392/67534796-acfeb380-f684-11e9-81fc-42a530e2b3dd.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-10-25 00:38](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-546154200):

`ifconfig` now shows an IP address for the WiFi adapter.
![image](https://user-images.githubusercontent.com/419392/67534884-0e268700-f685-11e9-9cb1-673706d8b68b.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-11-20 00:07](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-555773672):

Correct orientation for insertion / removal of tools from the Version 2 Tool Changer. 
![image](https://user-images.githubusercontent.com/419392/69197573-a67a2500-0ae6-11ea-937c-cc6d421945ed.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-20 22:08](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-601931191):

Re-inserting the SD Card. SEE:
https://github.com/HaddingtonDynamics/Dexter/wiki/SD-Card-Image
for critical instructions!

![image](https://user-images.githubusercontent.com/419392/77209850-a736be00-6abc-11ea-9a6d-8ea40118f6dd.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-03 00:23](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-637883248):

Dexter HDI packedin case:
![image](https://user-images.githubusercontent.com/419392/83582361-281b2880-a4f6-11ea-931d-595f7a4cbbac.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-05 00:58](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-639196381):

Dexter HDI, removal from packing case
![delme](https://user-images.githubusercontent.com/419392/83826232-3e5cec00-a690-11ea-93a9-5d721a59ebe1.jpg)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-05 01:24](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-639203419):

Alignment mark on J1 on Dexter HDI
![J1align](https://user-images.githubusercontent.com/419392/83826349-8845d200-a690-11ea-8bba-e899748f2fb3.jpg)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-05 02:03](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-639213902):

Dexter HDI with skin showing expected blue light.
![delme3](https://user-images.githubusercontent.com/419392/83826550-0609dd80-a691-11ea-8210-35bf60e937d9.jpg)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-28 18:24](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-665202060):

Dexter FPGA control system block diagram.
![DexterFullControlSystem](https://user-images.githubusercontent.com/419392/88705673-b827b980-d0c4-11ea-9a36-98ca23db1be0.PNG)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-28 18:26](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-665202863):

Dexter Control System, "Keep Position" section expanded. Note that integration is provided by the stepper motor /after/ the PID section. 
![DexterKeepMode](https://user-images.githubusercontent.com/419392/88705907-03da6300-d0c5-11ea-9963-557346285f53.PNG)

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) commented at [2020-08-26 21:46](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-681140689):

![CoM_Diagram](https://user-images.githubusercontent.com/26582517/91360228-e0c9ce80-e7aa-11ea-9465-29e0f4eb875d.PNG)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-09-16 00:41](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-693102752):

Animation of one encoder sensor as the slot passes the mask.
![DexterEyeAnimation](https://user-images.githubusercontent.com/419392/93278868-a6849900-f77a-11ea-94a1-3a8694d31c93.gif)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-09-16 00:42](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-693102894):

Animation of the encoder showing the phase between the two sensors. 
![DexterEncoderAnimation](https://user-images.githubusercontent.com/419392/93278905-c025e080-f77a-11ea-936e-0685ca073cac.gif)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-09-23 16:27](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-697643659):

Diagram of link lengths 4 and 5

![image](https://user-images.githubusercontent.com/419392/94041118-a9851800-fd7e-11ea-8a59-1c177d40a7a9.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-10-15 21:44](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-709607156):

Dexter HDI Motion Envelope - Top View
![Dexter HDI Motion Envelope - Top View](https://user-images.githubusercontent.com/419392/96189198-e911d080-0ef4-11eb-868c-c63a0f8b30f6.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-10-15 21:54](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-709610601):

Dexter HDI Motion Envelope - Side View
![Dexter HDI Motion Envelope - Side View](https://user-images.githubusercontent.com/419392/96189880-30e52780-0ef6-11eb-8ffd-4e77d4b6e493.png)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-10-15 21:57](https://github.com/HaddingtonDynamics/Dexter/issues/65#issuecomment-709611797):

Dexter HDI Joints Range Of Motion
![Dexter HDI Joints Range Of Motion](https://user-images.githubusercontent.com/419392/96190203-b1a42380-0ef6-11eb-92c3-84d30b67d975.png)


-------------------------------------------------------------------------------

# [\#64 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/64) `closed`: USB host connector on ZedBoard inaccessible. 
**Labels**: `Hardware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-05-03 19:49](https://github.com/HaddingtonDynamics/Dexter/issues/64):

The ZedBoard supports the connection of USB devices (e.g. cameras, keyboard, data storage, etc...) but there is no way to get to the connector currently because it is blocked by the fan mount. Moving the fan to the back of a new Skin (see issue #4 "Skins") and ducting the air to the stepper drivers would open up that space. The skin could also perhaps support a small USB hub so that more than one device could be connected. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-11-04 18:35](https://github.com/HaddingtonDynamics/Dexter/issues/64#issuecomment-549488353):

This is resolved on the new HDI design which provides a separate fan mount. It might be possible to apply that mount to a Dexter HD with a little work. Ask if you want the STL file (all HDI STL files will be released in the future, but are not currently available except on a case by case basis.)


-------------------------------------------------------------------------------

# [\#63 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/63) `open`: Joint 6/7 movement not synchronized with Joints 1-5
**Labels**: `Firmware`, `Gateware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-04-26 00:00](https://github.com/HaddingtonDynamics/Dexter/issues/63):

When move all joints or move to commands are issued with values for Joint 6 / 7 (the Dynamixel servos) those angles are not placed on the queue in the FPGA and so are not coordinated by the FPGA with the motion of the other joints. The FPGA queue does not currently support accepting or sending position commands to the Dynamixels. 

The workaround is to do a empty_instruction_queue() ('F' oplet) between each movement command. This prevents any smooth transitions from one movement to the next; the arm has to stop at each point before continuing to the next. 

This also doesn't resolve the lack of interpolated movement. Joints 1-5 will all complete their movement at the same time, but Joints 6 and 7 will complete their movements in their own time, either before or after the others. 




-------------------------------------------------------------------------------

# [\#62 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/62) `closed`: AdcCenters not updated in FPGA when written to file.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-04-17 20:22](https://github.com/HaddingtonDynamics/Dexter/issues/62):

When a human is calibrating the joint eyes on Dexter via DDE, they might expect that when the new centers are saved to the robot, they have effect immediately. This is NOT the case. The robot must be power cycled for them to be read into the FPGA from the file DDE writes to the robot.

Commit https://github.com/HaddingtonDynamics/Dexter/commit/0d766de6320b2e64755c999c5daa912108d5f2c9 resolves this by detecting an updated AdcCenters.txt file IF written via write_to_robot and then re-loads that file immediately. 

DDE should still advise the use to restart the robot because there is no way to know if this new function has been implemented in Dexter. 

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-04-18 01:26](https://github.com/HaddingtonDynamics/Dexter/issues/62#issuecomment-484320471):

How about if each Dexter has a Manufacture date on it.
We'll know what software was shipped on its SD card,
then we can know what to tell the users.
Maybe manufacture date is something DDE could retrieve
from a file of "specs" on dexter.

On Wed, Apr 17, 2019 at 4:22 PM JamesNewton <notifications@github.com>
wrote:

> Assigned #62 <https://github.com/HaddingtonDynamics/Dexter/issues/62> to
> @cfry <https://github.com/cfry>.
>
> —
> You are receiving this because you were assigned.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/62#event-2283888807>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/AAJBG7NXNIWM5K4BACXE733PQ6BIHANCNFSM4HGXRFDQ>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-04-18 02:38](https://github.com/HaddingtonDynamics/Dexter/issues/62#issuecomment-484333811):

The issue is that read from robot isnt supported on early Dexters and will
actually crash some of them.

On Wed, Apr 17, 2019, 6:26 PM cfry <notifications@github.com> wrote:

> How about if each Dexter has a Manufacture date on it.
> We'll know what software was shipped on its SD card,
> then we can know what to tell the users.
> Maybe manufacture date is something DDE could retrieve
> from a file of "specs" on dexter.
>
> On Wed, Apr 17, 2019 at 4:22 PM JamesNewton <notifications@github.com>
> wrote:
>
> > Assigned #62 <https://github.com/HaddingtonDynamics/Dexter/issues/62> to
> > @cfry <https://github.com/cfry>.
> >
> > —
> > You are receiving this because you were assigned.
> > Reply to this email directly, view it on GitHub
> > <https://github.com/HaddingtonDynamics/Dexter/issues/62#event-2283888807
> >,
> > or mute the thread
> > <
> https://github.com/notifications/unsubscribe-auth/AAJBG7NXNIWM5K4BACXE733PQ6BIHANCNFSM4HGXRFDQ
> >
> > .
> >
>
> —
> You are receiving this because you authored the thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/62#issuecomment-484320471>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/AADGMQEYZTQ2WMY5GFWBO7DPQ7E4FANCNFSM4HGXRFDQ>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-28 18:21](https://github.com/HaddingtonDynamics/Dexter/issues/62#issuecomment-525864175):

@cfry Based on our moving to using read from robot to get the Defaults.make_ins file on first connect, I'm assuming that backwards compatibility is no longer being taken as a concern and that anyone who's Dexter crashes on connect will be told to update the firmware (and gateware to match). So I'm closing this issue as the base issue was resolved in that April commit.


-------------------------------------------------------------------------------

# [\#61 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/61) `closed`: Fix "freakout" / tourettes when encoder eye errors

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-04-05 00:29](https://github.com/HaddingtonDynamics/Dexter/issues/61):

When the eye isn't set correctly for a joint encoder, or when something external causes a failure of the encoder (gunk blocking a slot, electrical failure, the sensor block getting bumped, etc..) the reported position of the joint can suddenly jump and become unstable. It will show the joint moving in a way that is impossible; moving faster than physics would allow. 

One possible solution is a monitor thread which keeps track of the change in reported position and reacts when it exceeds the limits of possibility. At a minimum, the robot should switch to open loop mode and report an error back to DDE.



#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-04-05 01:48](https://github.com/HaddingtonDynamics/Dexter/issues/61#issuecomment-480121528):

It sounds like an interesting pattern-recognition
program to write that could detect
physical bugs in the robot and report
back to the user a hypothesis about
what the physical bug is.
A smart error message, as it were.


On Thu, Apr 4, 2019 at 8:29 PM JamesNewton <notifications@github.com> wrote:

> When the eye isn't set correctly for a joint encoder, or when something
> external causes a failure of the encoder (gunk blocking a slot, electrical
> failure, the sensor block getting bumped, etc..) the reported position of
> the joint can suddenly jump and become unstable. It will show the joint
> moving in a way that is impossible; moving faster than physics would allow.
>
> One possible solution is a monitor thread which keeps track of the change
> in reported position and reacts when it exceeds the limits of possibility.
> At a minimum, the robot should switch to open loop mode and report an error
> back to DDE.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/61>, or mute the
> thread
> <https://github.com/notifications/unsubscribe-auth/ABITfVl8FlToVFBEgNAOksZrmcKJoqINks5vdpj5gaJpZM4cd86e>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-04-17 20:18](https://github.com/HaddingtonDynamics/Dexter/issues/61#issuecomment-484245223):

Commit https://github.com/HaddingtonDynamics/Dexter/commit/0d766de6320b2e64755c999c5daa912108d5f2c9 starts on this. The raw encoder angles give an accurate enough reading of current position IF:
1. The Joint encoder eyes are calibratable. E.g. AdcCenters.txt is correctly set and the eyes are good.
2. There appears to be a startup offset which is pretty serious. e.g. when the robot powers up, 0 may be shown as 5000, but it is /always/ off by 5000 for that joint from then on. The code records the first reading and then subtracts that from all following readings. No idea why.

Velocity change sensing is also in there, but doesn't appear to reliably detect encoder mis-calibration. Even setting the center outside the eye only results in incorrect angles, not in random skipping of the angles. It /does/ trigger during tourettes episodes, but not for the expected joint or reliably enough to use. 

TODO: MUCH.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-11 01:16](https://github.com/HaddingtonDynamics/Dexter/issues/61#issuecomment-510287828):

Commit https://github.com/HaddingtonDynamics/Dexter/commit/4c595f28cb51038c252ae70aef14c245db663d84
adds boundary checking / limit to the 
https://github.com/HaddingtonDynamics/Dexter/commit/17c4c5e37560ef4027b8198a131e54334226ff0f
changes which monitor velocity and switch to open loop mode if they are exceeded several times in a row. This /should/ stop freakouts in the future.


-------------------------------------------------------------------------------

# [\#60 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/60) `open`: Job engine to run DDE jobs on Dexter
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-03-28 00:50](https://github.com/HaddingtonDynamics/Dexter/issues/60):

Starting this issue to record development history so we know why something was done in the future. The current status (only available on the very latest images) is here:<br>
https://github.com/HaddingtonDynamics/Dexter/wiki/DDE/#job-engine-on-dexter

Goal: Make it easy for DDE on a PC to write jobs to Dexter which are then run ON Dexter. These are one time jobs, with DDE in control of dispatch, so you don't have to SSH in, or depend on SAMBA or anything else. The functionality can even be integrated into DDE. 

And this allows us to start the job ourselves, it doesn't have to be started automatically when Dexter fires up. Experts can figure out how to add an [/etc/rc.local](https://www.raspberrypi.org/documentation/linux/usage/rc-local.md)

First, we must have DDE on Dexter. In this case, we don't need to make a distributable package, we just want to run the source. And having the source directly run means we can develop on Dexter and also use parts of it in other ways (see Job Engine below). So instead of installing the Electron package, we just install the source and use npm to pull in the dependencies. Note: This requires the 16.04 version of the operating system on Dexter, and the Dexter must be connected to the internet (e.g. plugged into a router, or wifi)
````
$ cd /root/Documents
$ git clone https://github.com/cfry/dde
$ cd dde
$ npm i
$ npm run start
````
Note: If you need to go back to a prior version, use `git checkout v3.5.2` or whatever. v3.0.7 is known to work as well. Also, the `node run start` may not work until after you comment out the serial stuff (see below). 

Of course, the GUI part of the app will only be visible with an X-Server running and since Dexter does not have a video adapter, this must be a remote the [X-Windows Desktop](Dexter-Networking#x-windows). On the current images, an icon is provided to launch DDE from the desktop when logged in via X-Windows. The program takes a while to load (need faster SD Card and interface?) but operation isn't horribly slow.

A "dde_apps" folder for the GUI run of DDE is created under the "/root" folder (alongside Documents, not in it) for the DDE application. Setting the dexter0 ip address to `localhost` in the `/root/dde_apps/dde_init.js` file allows local connection of DDE to DexRun. 

To run DDE jobs without the full DDE GUI interface, e.g. via [SSH](Dexter-Networking#shell-access-via-ssh), you can start them from `~/Documents/dde` with the command:<br>
`node  core  define_and_start_job  job_file.dde`

There are a few things to tweek before that will work:

From /root/Documents/dde, `nano core/serial.js` and comment out the line: `const SerialPort = require('serialport')`. There is some mismatch between the component that manages serial ports on our OS vs others. 

**Job Engine Initialization:** When run for the first time, the job engine creates a `dde_init.js` file in the `/root/Documents/dde_apps` folder. (note this is different than for the GUI DDE on Dexter which is in `/root/dde_init.js`). The job engine defaults to simulate, so the jobs don't actually make the robot move until the dde_init file is edited to add `,simulate: false` after the IP address in the definition of dexter0. The IP address is set to `localhost` so it will work no matter what IP address Dexter is actually assigned.

`/root/Documents/dde_apps/dde_init.js`:
````Javascript
persistent_set("ROS_URL", "localhost:9090") //required property, but you can edit the value.
persistent_set("default_dexter_ip_address", "localhost") //required property but you can edit the value.
persistent_set("default_dexter_port", "50000") //required property, but you can edit the value.
new Dexter({name: "dexter0", simulate: false}) //dexter0 must be defined.
````

Keep in mind the version of DDE on Dexter may need to be updated.  It's 3.0.7 on the initial release of the 16.04 image.

You may want to use
`node  core  define_and_start_job /srv/samba/share/job_file.dde`

When you 'run a job' as defined above, it sets window.platform to "node". If you are in dde, `window.platform == "dde"` will evaluate to true. That means you can customize any code written based on this "platform" i.e.
````Javascript
if(window.platform == "node")      { /* hey I'm in node. */ }
else if (window.platform == "dde") { /* we're in dde! */ }
````

The system software takes advantage of this. One important case is that the "out" function is defined as:
````Javascript
function out(val="", color="black", temp=false, code=null){
    if(window.platform == "node") { console.log(val) }
    else { /* do formatting and print to DDE's Output pane */ }
}
````
Thus when running on node, 'out' only pays attention to its first arg, and it sends the first arg directly to the console.

On the development image, (for the next release) there is an updated /etc/systemd/system path and service which looks for any changes in the /srv/samba/share/job folder and when seen, executes the following script "RunJob" (also in that folder):
````
#!/usr/bin/env bash

cd /root/Documents/dde
for i in /srv/samba/share/job/*.dde; do
        [ -f "$i" ] || break
        echo "running $i"
        sudo node core define_and_start_job $i >> $i.$(date +%Y%m%d_%H%M%S).log
        # must use sudo or node doesnt know who the user is and cant find the dde_apps folder.
        rm $i
done
````
which then fires off the job engine, does the job, and puts the resulting output in a <filename>YYMMDD_HHMMSS.log file.

 For example:
````
new Job({name: "test_job_engine", do_list: [
	Dexter.write_to_robot(
    	"new Job({name: \"my_job\", do_list: [Dexter.move_all_joints([30, 45, 60, 90, 120]), Dexter.move_all_joints([0, 0, 0, 0, 0])]})"
        , "job/try.dde"
        )
    ]})
````
makes Dexter move, and then the file /job/try.dde.20190327_233018.log contains:
````
in file: /root/Documents/dde/core/index.js
top of run_node_command with: /usr/bin/node,/root/Documents/dde/core,define_and_start_job,/srv/samba/share/job/try.dde
top of node_on_ready
operating_system: linux
dde_apps_dir: /root/Documents/dde_apps
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;loading persistent values from /root/Documents/dde_apps/dde_persistent.json
Done loading persistent values.
load_files called with: dde_init.js
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;loading file: /root/Documents/dde_apps/dde_init.js
Done loading file: /root/Documents/dde_apps/dde_init.js
cmd_name: define_and_start_job args: /srv/samba/share/job/try.dde
load_files called with: /srv/samba/share/job/try.dde
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;loading file: /srv/samba/share/job/try.dde
Done loading file: /srv/samba/share/job/try.dde
Job: my_job pc: 0 <progress style='width:100px;' value='0' max='2'></progress> of 2. Last instruction sent: {instanceof: move_all_joints 30,45,60,90,120}&nbsp;&nbsp;<button onclick='inspect_out(Job.my_job)'>Inspect</button>
Creating Socket for ip_address: localhost port: 50000 robot_name: dexter0
Now attempting to connect to Dexter: dexter0 at ip_address: localhost port: 50000 ...
Succeeded connection to Dexter: dexter0 at ip_address: localhost port: 50000
Job: my_job pc: 0 <progress style='width:100px;' value='0' max='2'></progress> of 2. Last instruction sent: {instanceof: move_all_joints 30,45,60,90,120}&nbsp;&nbsp;<button onclick='inspect_out(Job.my_job)'>Inspect</button>
Job: my_job pc: 1 <progress style='width:100px;' value='1' max='2'></progress> of 2. Last instruction sent: {instanceof: move_all_joints 0,0,0,0,0}&nbsp;&nbsp;<button onclick='inspect_out(Job.my_job)'>Inspect</button>
Job: my_job pc: 2 <progress style='width:100px;' value='2' max='3'></progress> of 3. Last instruction sent: Dexter.get_robot_status &nbsp;&nbsp;<button onclick='inspect_out(Job.my_job)'>Inspect</button>
top of Job.stop_for_reason with reason: Finished all do_list items.
Job: my_job pc: 3 <progress style='width:100px;' value='3' max='3'></progress> of 3. Done.&nbsp;&nbsp;<button onclick='inspect_out(Job.my_job)'>Inspect</button>
Done with job: my_job
````
I'm happy about the ability to get a job onto Dexter and run it /on Dexter/ using nothing more than DDE. I like that the job file is deleted after it's run. I like that systemd is /apparently/ smart enough not to start the script until the file is done being written (apparently?) and I like that the output is retained. 

What I don't like is that it's retained forever. If people use that alot, it's going to fill up the folder with junk. I see a few easy solutions and some harder ones.
1. When a new job is run, log files from the prior jobs are erased. e.g. add rm /srv/samba/share/job/*.log to the RunJob script. 
2. When DDE "picks up" the log file, it could write back a zero length string to that file name, and DexRun could be changed to make it just delete the file when it is written a zero length string. (I really don't like that idea, it has MANY problems. 
3. Implement shelling out to bash when read_from_robot is called with a `<filename>` string. This on the TODO list anyway, sometime after slaying the dragon. (note: it's on READ not write, because the output of the bash shell gets buffered back to DDE, you write the file, then read the result, which actually triggers running the file). I don't want to do that yet, because it's complex.

Which reminds me, there is currently no way to know what the log file name will be, so DDE can't really read back the result. Since the job file gets whacked anyway, I think the log file should NOT include the date and time and just be <file>.log. So the test.dde job would result in a test.dde.log file, DDE can read that, and (as per option 1) next time you write test.dde, the old test.dde.log file gets whacked automatically and replaced with a new one. That seems like a simple solution, no? 

Last problem, DDE doesn't know when the job is finished. So the log file keeps expanding, and shouldn't be read_from_robot'ed until it's done. I think the solution to that is to always write the log into the file with date and time, then when the job has finished, rename that file to the <file>.log name. DDE can poll and when it returns more than a null string, it can be sure it's getting the entire string. 




#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-03-29 00:52](https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-477823752):

Ok, a few changes: 

1. There is a sub folder under job called `run`, and that run folder is what is watched and triggers the service, not the job folder. That allows things in job to be edited / changed without re-triggering the service. 

2. There is a sub folder under job called `logs` where log files end up. 

3. The systemd files were changed as follows:<br>
ddejob.path
````
[Unit]
Description=DDEJob
[Path]
PathModified=/srv/samba/share/job/run
[Install]
WantedBy=multi-user.target
````

ddejob.service
````
[Unit]
Description=DDEJob
[Service]
ExecStart=/srv/samba/share/job/RunJobs
````
and then started with
````
sudo systemctl enable ddejob.path
sudo systemctl start ddejob.path
````
Note: if you edit those, do a 
````
sudo systemctl daemon-reload
````

The RunJob script is:
````
#!/usr/bin/env bash

# first remove prior job logs and junk

cd /root/Documents/dde
for i in /srv/samba/share/job/run/*.dde; do
        [ -f "$i" ] || break
        jobname=$(basename -- "$i")
        echo "running $jobname"
        echo "Logfile for $jobname on $(date +%Y%m%d_%H%M%S)">/srv/samba/share/job/logs/$jobname.tmp
        sudo node core define_and_start_job $i >> /srv/samba/share/job/logs/$jobname.tmp
        # must use sudo or node doesnt know who the user is and cant find the dde_apps folder.
        rm /srv/samba/share/job/logs/*.log
        mv /srv/samba/share/job/logs/$jobname.tmp /srv/samba/share/job/logs/$jobname.log
        # copy large log files only after they are fully written so dde doesnt seem them until complete
        rm $i
        # remove the job file
done
````
so now the DDE job: 
````
new Job({name: "test_job_engine", do_list: [
	Dexter.write_to_robot(
    	"new Job({name: \"my_job\", do_list: [Dexter.move_all_joints([30, 45, 60, 90, 120]), Dexter.move_all_joints([0, 0, 0, 0, 0])]})"
        , "job/run/try.dde"
        )
    ]})
````
has the same result, but we can add code to `read_from_robot("my_job_log", "job/logs/try.dde.log")` and when that returns nothing, just loop until it returns the result. 

Seems to work quite nicely.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-03-29 18:24](https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-478101767):

Rather than write the file to

"job/run/try.dde"

How about writing it to

"job/run/my_job.dde"

If the script is just looking for any files

in the job/run  folder,'

then it will be able to find it

AND in case something goes wrong,

we can at least easily identify

what job it is.

Same thing for

job/logs/try.dde.log

IE DDE will know the name of the job

it wants to check, so can ask explicitly

for job/logs/my_job.dde.log

But if something is left hanging around, etc.

then we'll be able to debug easier.

_____

I've been doing a bunch of design work on the

DDE side to support this today.

I'd like to be able to send a cmd

to Dexter to stop such a job.

Something like:

Dexter.write_to_robot("stop_job my_job")

To implement, I guess you have to

save away the process id of the node

process associated to the job name.

Then if you receive

"stop_job my_job"

do

kill -9 my_job_process_id

because, as we all know,

a -8 kill sometimes just isn't strong enough :-)



On Thu, Mar 28, 2019 at 8:52 PM JamesNewton <notifications@github.com>
wrote:

> Ok, a few changes:
>
>    1.
>
>    There is a sub folder under job called run, and that run folder is
>    what is watched and triggers the service, not the job folder. That allows
>    things in job to be edited / changed without re-triggering the service.
>    2.
>
>    There is a sub folder under job called logs where log files end up.
>    3.
>
>    The systemd files were changed as follows:
>
>    ddejob.path
>
> [Unit]
> Description=DDEJob
> [Path]
> PathModified=/srv/samba/share/job/run
> [Install]
> WantedBy=multi-user.target
>
> ddejob.service
>
> [Unit]
> Description=DDEJob
> [Service]
> ExecStart=/srv/samba/share/job/RunJobs
>
> and then started with
>
> sudo systemctl enable ddejob.path
> sudo systemctl start ddejob.path
>
> Note: if you edit those, do a
>
> sudo systemctl daemon-reload
>
> The RunJob script is:
>
> #!/usr/bin/env bash
>
> # first remove prior job logs and junk
>
> cd /root/Documents/dde
> for i in /srv/samba/share/job/run/*.dde; do
>         [ -f "$i" ] || break
>         jobname=$(basename -- "$i")
>         echo "running $jobname"
>         echo "Logfile for $jobname on $(date +%Y%m%d_%H%M%S)">/srv/samba/share/job/logs/$jobname.tmp
>         sudo node core define_and_start_job $i >> /srv/samba/share/job/logs/$jobname.tmp
>         # must use sudo or node doesnt know who the user is and cant find the dde_apps folder.
>         rm /srv/samba/share/job/logs/*.log
>         mv /srv/samba/share/job/logs/$jobname.tmp /srv/samba/share/job/logs/$jobname.log
>         # copy large log files only after they are fully written so dde doesnt seem them until complete
>         rm $i
>         # remove the job file
> done
>
> so now the DDE job:
>
> new Job({name: "test_job_engine", do_list: [
> 	Dexter.write_to_robot(
>     	"new Job({name: \"my_job\", do_list: [Dexter.move_all_joints([30, 45, 60, 90, 120]), Dexter.move_all_joints([0, 0, 0, 0, 0])]})"
>         , "job/run/try.dde"
>         )
>     ]})
> ```
> has the same result, but we can add code to `read_from_robot("my_job_log", "job/logs/try.dde.log")` and when that returns nothing, just loop until it returns the result.
>
> Seems to work quite nicely.
>
>
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-477823752>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITfRgFjP8nrmmgTRCzrphJZrQdpKYYks5vbWO1gaJpZM4cPDa7>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-21 19:19](https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-523611130):

This has been included on the prior image and on the upcoming one. 

The ability to run BASH shells is a much better / faster way to trigger job engine code if needed, as enabled by #20 (be sure to keep polling via "r 1 `" until the job engine completes") 

Also, if DDE gains the ability to SSH into Dexter, that may provide an even better interface. 

In any case, it's there, it works, it's based on DDE 3.0.7 but that will be updated in the future.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-16 22:10](https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-599780624):

### Updating DDE on Dexter for Interactive Jobs from Browser

Changes made in DDE 3.5.6 cause this to not work on Dexter because of a package for camera control that has problems compiling. DDE 3.5.2 works but you must check it out and do an `npm run rebuild`

For 3.5.2 I [connected to Dexter via SSH](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#shell-access-via-ssh) and did:
````
cd /root/Documents
mv ./dde ./dde_OLD
git clone https://github.com/cfry/dde
cd dde
git checkout v3.5.2
npm install
````

### Browser Job Engine Interface
To enable full job control from the browser of Job Engine jobs, the following is also needed:
- Updated httpd.js file under the share/www folder https://github.com/HaddingtonDynamics/Dexter/commit/27ca559a4f1f58f0e1cecec854ab941a60bdaf89
- New 'jobs.html' file under share/www https://github.com/HaddingtonDynamics/Dexter/commit/081cd084e56b2249d1816f6d580e7cb8cbc59923
-  The je_and_browser_code.js file from the dde/core folder, in the share/www folder. You can copy that file from dde/core to the share/www folder, or (better) use the following command from share/www to create a symlink: 
`ln -s /root/Documents/dde/core/je_and_browser_code.js je_and_browser_code.js`
You may need to npm install some packages.
````
cd /srv/samba/share/www
npm install formidable
npm install modbus-serial
````

With these changes, you should be able to access /jobs.html at Dexters IP address and start, stop, and communicate with jobs running on the robot. It's probably a good idea to edit the index.html file in the share/www folder to add a link to that page. e.g.:
`<li><a href="/jobs.html">Job Engine</a> Run DDE jobs locally on Dexter</li>`

with this new setup, code like the following, file name `dexter_user_interface.dde` in the share/dde_apps folder runs nicely and allows bidirectional communications and control from the browser. 

````
//////// Job Example 7g: Dexter User Interface
//Interactivly control Dexter's joints.
function dexter_user_interface_cb(vals){
    debugger;
    let maj_array = [vals.j1_range, vals.j2_range, vals.j3_range, vals.j4_range,
                     vals.j5_range, vals.j6_range, vals.j7_range]
    let instr = Dexter.move_all_joints(maj_array)
    Job.insert_instruction(instr, {job: vals.job_name, offset: "end"})
}
function init_dui(){
  show_window({title: "Dexter User Interface",
               width: 300,
               height: 220,
               y: 20,
               job_name: this.name, //important to sync the correct job.
               callback: dexter_user_interface_cb,
               content:`
Use the below controls to move Dexter.<br/>
J1: <input type="range"  name="j1_range"  value="0"  min="-100" max="100" data-oninput="true"/><br/>
J2: <input type="range"  name="j2_range"  value="0"  min="-100" max="100" data-oninput="true"/><br/>
J3: <input type="range"  name="j3_range"  value="0"  min="-100" max="100" data-oninput="true"/><br/>
J4: <input type="range"  name="j4_range"  value="0"  min="-100" max="100" data-oninput="true"/><br/>
J5: <input type="range"  name="j5_range"  value="0"  min="-100" max="100" data-oninput="true"/><br/>
J6: <input type="range"  name="j6_range"  value="0"  min="-100" max="100" data-oninput="true"/><br/>
J7: <input type="range"  name="j7_range"  value="0"  min="-100" max="100" data-oninput="true"/><br/>
`
})}

new Job({
    name: "dexter_user_interface",
    when_stopped: "wait",
    do_list: [init_dui
]})
````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-28 01:41](https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-605376411):

## Serial Port

We generally recommend connecting your serial devices to the PC controlling Dexter rather than direct to Dexter because support for serial ports has been difficult with the dde "job engine" on the robot. DDE manages serial devices on the PC just fine, but for some strange reason, we can't seem to rebuild the serial module for the version of node in use. When we try to `require("serialport")` we get the following error messages:
````
/root/Documents/dde/node_modules/bindings/bindings.js:91
        throw e
        ^

Error: The module '/root/Documents/dde/node_modules/@serialport/bindings/build/Release/bindings.node'
was compiled against a different Node.js version using
NODE_MODULE_VERSION 57. This version of Node.js requires
NODE_MODULE_VERSION 67. Please try re-compiling or re-installing
the module (for instance, using `npm rebuild` or `npm install`).
    at Object.Module._extensions..node (internal/modules/cjs/loader.js:750:18)
    at Module.load (internal/modules/cjs/loader.js:620:32)
    at tryModuleLoad (internal/modules/cjs/loader.js:560:12)
    at Function.Module._load (internal/modules/cjs/loader.js:552:3)
    at Module.require (internal/modules/cjs/loader.js:657:17)
    at require (internal/modules/cjs/helpers.js:22:18)
    at bindings (/root/Documents/dde307/node_modules/bindings/bindings.js:84:48)
    at Object.<anonymous> (/root/Documents/dde307/node_modules/@serialport/bindings/lib/linux.js:1:98)
    at Module._compile (internal/modules/cjs/loader.js:721:30)
    at Object.Module._extensions..js (internal/modules/cjs/loader.js:732:10)
````

`npm rebuild` does not help. 

`npm install serialport` does not help.

However, if we start in a fresh folder, and `npm install serialport` we can write little serial programs that work just great, in that folder. Something in the dde file setup is causing the serialport module to stay stuck in the wrong version. 

A complete HACK to solve this is the following:
````
cd /root/Document
mkdir temp
cd temp
npm install serialport
cd /root/Document/dde/node_modules
mv @serialport @save
mv serialport save
cp -r /root/Documents/temp/node_modules/@serialport .
cp -r /root/Documents/temp/node_modules/serialport .
````
having done that, serial ports now work in the Job Engine folder (/root/Documens/dde).  Here is a sample node.js program that works with some simple Arduino code which just echos back text:
````js
const SerialPort = require('serialport');
const Readline = require('@serialport/parser-readline')

const port_path = "/dev/ttyUSB0"
let cmd = "41"
let port = {}

function port_listener(line) {
        console.log(">"+line)
        port.close() //done, close so code ends
        }

function port_IO(path) {
        console.log("trying port:" + path)
        port = new SerialPort(path, {
                baudRate: 9600
                })
        //Make a line parser. Several other types exist. see:
        //https://serialport.io/docs/api-parsers-overview
        const parser = new Readline()
        port.pipe(parser)
        parser.on('data', port_listener)

        port.on('open', function() {
                port.flush() //dump prior data
                port.write(cmd)
                console.log('<'+cmd)
                })

        port.on('error', function(err) {
                console.log('Error: ', err.message)
                })
        }

SerialPort.list().then(ports => {
  console.log("Found serial devices:");
  ports.forEach(function(port) {
    console.log("---"); //separator
    console.log("path:"+port.path);
    console.log("pnpId:"+port.pnpId);
    console.log("mfgr:"+port.manufacturer);
    if (port.path == port_path) {//found our port
        port_IO(port_path)
        }
  });
  if (!port_path && ports.length == 1) {
        //no path set, 1 found: guess!
        port_IO(ports[0].path)
        }

});
console.log("Start Serial")
````

To work with Serial devices in a .DDE Job Engine job, we must use the low level serial support in DDE (Serial Robots are not yet fully supported). The following code works well with an OpenMV camera which has been programmed to return data about barcodes, tags, and anything orange. 

````js
/* To find the port on Dexter, start with device disconnected, ssh in and enter:
ls /dev/tty*
then connect the device and repeat the command. Look for the difference.
*/
var Open_MV1_path = "/dev/ttyACM1" //"COM5" //Change to device's port name
var Open_MV_options = {
	baudRate: 115200,
    DATABITS: 8,
    STOPBITS: 1,
    PARITY: 0
}

var Open_MV0_path = "/dev/ttyACM0" //in my testing, this is actually an Arduino, 'cause I only have one camera
/*var Open_MV0_options = {
	baudRate: 115200,
    DATABITS: 8,
    STOPBITS: 1,
    PARITY: 0
}*/

new Job({
	name: "OpenMV_Test",
    show_instructions: false,
    inter_do_item_dur: 0,
    when_stopped: function(){serial_disconnect(Open_MV0_path); serial_disconnect(Open_MV1_path);},
    do_list: [
    	init,
		  main
    ]
  })

function init(){
  let CMD = []
  CMD.push(connectSerial(Open_MV0_path, Open_MV_options))
  CMD.push(connectSerial(Open_MV1_path, Open_MV_options))
  //CMD.push(function(){clear_output()})
  return CMD
}

var clear_flag = true
function main(){
	return Robot.loop(true, function(){
    let obj = get_openmv_obj()
    if(is_orange_blob(obj)){
    	if(clear_flag){ 
    		//beep({dur: 0.1, frequency: 800, volume: 1})
    		clear_flag = false
        //out("Orange Blob: {x: " + obj.x + ", y: " + obj.y + "}")
        console.log("*** Orange Blob: {x: " + obj.x + ", y: " + obj.y + "}")
        set_serial_string(Open_MV0_path, "13L\n")
        
        }
      }
    else if(is_april_tag(obj)){
    	if(clear_flag){
    		//beep({dur: 0.1, frequency: 800, volume: 1})
    		clear_flag = false
        //out("April Tag: {id: " + obj.id + ", angle: " + Math.round(obj.z_rotation*360/(2*Math.PI)) + "}")
        console.log("*** April Tag: {id: " + obj.id + ", angle: " + Math.round(obj.z_rotation*360/(2*Math.PI)) + "}")
        }
      }
    else if(is_bar_code(obj)){
    	if(clear_flag){
    		clear_flag = false
        //out("Bar Code: {value: " + obj.payload + "}")
        console.log("*** Bar Code: {value: " + obj.payload + "}")
        set_serial_string(Open_MV0_path, "13H\n")
        }
      }
    else if(is_cam_no(obj)){
    	if(clear_flag){
    		clear_flag = false
        console.log("*** Camera {value: " + obj.camno + "}")
    		//beep({dur: 0.1, frequency: 800, volume: 1})
        //speak({speak_data: "a"}) //??? Stops the serial data coming in (!?)
        }
      }
    else if(is_image(obj)){ //TODO: Returned data isn't a valid object, need "" around hex
    	if(clear_flag){
    		clear_flag = false
        console.log("*** image {value: " + obj.image_length + "}")
        }
      }
    else{
    	if(clear_flag==false){ 
    	  set_serial_string(Open_MV0_path, "?\n")
    	  set_serial_string(Open_MV1_path, "?\n")
      	}
    	clear_flag = true
      }
    })
  }

 /*
    april tag:
    [{"x":50, "y":19, "w":40, "h":40, "id":25, "family":16, "cx":70, "cy":39, "rotation":3.083047, "decision_margin":0.139966, "hamming":0, "goodness":0.000000, "x_translation":-0.540304, "y_translation":1.089546, "z_translation":-6.021238, "x_rotation":3.003880, "y_rotation":6.243485, "z_rotation":3.083047}]
    my_obj.id
    
    bar code:
    [{"x":259, "y":42, "w":1, "h":1, "payload":"000123ABCXYZ", "type":15, "rotation":0.000000, "quality":1}]
    my_obj.payload
    
    blob:
    [{"x":54, "y":69, "w":8, "h":16, "pixels":117, "cx":58, "cy":77, "rotation":1.522549, "code":1, "count":1, "perimeter":42, "roundness":0.283638}]
	my_obj.roundness
*/


//********** Serial Code Start **********
serial_port_init() //still required in 3.5.2, not in 3.5.10 or later
//Eval the code below to find serial device com port:
//serial_devices() //in later versions, this is available on DDE PC only
//serial_devices_async() //on Job Engine in later versions (DDE in Dexter)

var serial_delimiter = "\n"

function ourReceiveCallback(info_from_board, path) {
	debugger;
	if(info_from_board) {
		//let str = convertArrayBufferToString(info_from_board.buffer) NO!
		let s = serial_path_to_info_map[path]
		s.buffer += info_from_board.toString() //just accumulate all incoming data
		let split_str = s.buffer.split(s.item_delimiter) //break it up by the delimiter 
		if (split_str.length > 2){ //if we have a complete string between 2 delimiters
			let str = split_str[split_str.length - 2] //break out the last one (we could break out ALL)
			s.buffer = s.item_delimiter+ split_str[split_str.length - 1] //save the rest 
	      // notice that we much put the delimiter back because it was removed by the split
	      //out(str, "blue", true) //debugging only
	      
			if (str.length > 0){ //protect against empties (unnecessary?)
				s.current = str //save out latest data
				console.log(s.current+"\r")
				 }
			}
		}
	 }


function ourReceiveErrorCallback(info_from_board, path) {
  if(info_from_board) {
  	out("Serial Error on " + path + ":")
  	out(JSON.stringify(info_from_board))
  	debugger; //do not remove
  }
}

function get_serial_string(){ 
  return serial_path_to_info_map[Open_MV1_path].current
}

function set_serial_string(path, str){
	serial_path_to_info_map[path].port.write(str + "\n")
}

function connectSerial(serial_path, serial_options){
	return [function (){
		serial_connect_low_level(
		serial_path,      //com number string
		serial_options,  //options (baud, etc...)
		1,                //capture_n_items (unused)
		serial_delimiter, //item_delimiter (unused)
		true,             //trim_whitespace (unused)
		true,             //parse_items (unused)
		false,            //capture_extras (unused)
		ourReceiveCallback,
		ourReceiveErrorCallback
		)
	serial_path_to_info_map[serial_path].buffer = ""
	serial_path_to_info_map[serial_path].current = ""
	}]
}

function serial_disconnect(serial_path) {
    let info = serial_path_to_info_map[serial_path]
    if (info){
        if((info.simulate === false) || (info.simulate === "both")) {
            info.port.close(out)
        }
        delete serial_path_to_info_map[serial_path]
    }
}

function get_openmv_obj(){
	let my_string = get_serial_string()
    //out(my_string, "blue", true)
	if(!my_string){return undefined}
    let my_obj = {}
	try {my_obj = JSON.parse(my_string)[0]}
    catch(error){
    out("Bad data")}
    return my_obj
}

function is_april_tag(obj){
    return obj && obj.family
}

function is_orange_blob(obj){
    return obj && obj.roundness
}

function is_bar_code(obj){
    return obj && obj.payload
}

function is_cam_no(obj){
    return obj && obj.camno
}

function is_image(obj){
    return obj && obj.image_length
}
//********** Serial Code End **********

````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-06 01:48](https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-669634827):

### WebSocket Job Engine Interface (incl non-browser)

To use the websocket interface outside of the browser environment, potentially from any websocket capable environment and not only the browser, via the user_data variables. This requires a few lines being changed in the /srv/samba/share/www/httpd.js file. Specifically

- Add:
`      serve_job_button_click(browser_socket, mess_obj)`
after the line:
`      console.log("\n\nwss server received invalid message kind: " + mess_obj.kind)`

- Change the else clause at the end of serve_job_button_click to
```
    	let code 
        if(job_name === "keep_alive") { //happens when transition from keep_alive box checked to unchecked
        	code = "set_keep_alive_value(" + mess_obj.keep_alive_value + ")"
        }
        else {
          //code = "Job." + job_name + ".server_job_button_click()"
          //e.g. `web_socket.send(JSON.stringify({"job_name_with_extension": "dexter_message_interface.dde", "ws_message": "goodbye" }))`
            if (mess_obj.ws_message ) { // {"job_name_with_extension": jobname.dde, "ws_message": data}
              code = `Job.`+job_name+`.user_data.ws_message = '` + JSON.stringify(mess_obj.ws_message)  + `'`
              }
            else if (mess_obj.code) {
              code = mess_obj.code
            }
            else {
              code = 'Job.maybe_define_and_server_job_button_click("' + jobfile + '")'
              }
        }
        console.log("serve_job_button_click writing to job: " + job_name + " stdin: " + code)
        //https://stackoverflow.com/questions/13230370/nodejs-child-process-write-to-stdin-from-an-already-initialised-process
        job_process.stdin.setEncoding('utf-8');
        job_process.stdin.write(code + "\n")
        //job_process.stdin.end(); 
````

This allows us to send any "kind" of message (or one with no kind) to the job engine. And if we include a ws_message item in the object we send, it will be inserted into the jobs user_data.

For example:
````js
// File: /srv/samba/share/dde_apps/dexter_message_interface.dde
new Job({
    name: "dexter_message_interface",
    when_stopped: "wait",
    inter_do_item_dur: 2,
    show_instructions: false,
    user_data: {ws_message: "hello"},
    do_list: [
        Robot.loop(true, function(){ //in future versions, use Control.loop
        	if (this.user_data.ws_message) {
              out(this.user_data.ws_message)
              this.user_data.ws_message = undefined
              }
        	})
        ]})
        
````
Note: 
- The jobs file name must be the same as the job name. 
- The `show_instructions: false,` setting will keep the communications channel from being swamped as instructions execute.
- Setting `inter_do_item_dur: 2,` will slow down the job so you can see it operate. You should probably set that to a smaller number for better performance.

To use this, a web socket connection must be opened to Dexter on port 3001. e.g. 
`ws://192.168.1.142:3001/`

A large number of status and informational strings will be returned from the job engine to the onboard node server. To pick out the ones that were sent back from your job via "out", look for data wrapped in "<for_server>" tags, with a JSON object and a "kind" of "out_call". The data will be in the "val" attribute. e.g.
` <for_server>{"kind":"out_call","val":"APP:hello.","color":"black","temp":false,"code":null}</for_server>`

The val may be escaped JSON or binary data. For example, this is a returning ROS JointState message where the "val" is, itself, a JSON message:
`<for_server>{"kind":"out_call","val":"{\"header\":{\"seq\":0,\"stamp\":{\"secs\":1597802744.166809,\"nsecs\":1597802744166809000},\"frame_id\":\"\"},\"name\":[\"J1\",\"J2\",\"J3\",\"J4\",\"J5\",\"J6\",\"J7\"],\"position\":[0,0,0,0,0,-2.5914648733611805,0],\"velocity\":[0,0,0,0,0,0,0],\"effort\":[0,0,0,0,0,0,0]}","color":"black","temp":false,"code":null}</for_server>`

Here are some examples of other messages you might get
`<for_server>{"kind":"out_call","val":"(out call) stdin got line: Job.maybe_define_and_server_job_button_click(\"/srv/samba/share/dde_apps/ROS.dde\")\n","color":"black","temp":false,"code":null}</for_server>
<for_server>{"kind":"show_job_button","job_name":"helloworld","status_code":"interrupted","button_color":"rgb(255, 123, 0)","button_tooltip":"This Job was interrupted at instruction 3 by:\nUser stopped job\nClick to restart this Job."}</for_server>
<for_server>{"kind":"out_call","val":"Done with job: helloworld for reason: User stopped job","color":"black","temp":false,"code":null}</for_server>
In finish_job for job: helloworld id: 1
finish job calling close_readline`

To send data from the program that opened the connection into the job engine job, send a JSON formatted string through the web socket connection, with the name of the job file, and a "ws_message" string. For example: 
`'{"job_name_with_extension": "dexter_message_interface.dde", "ws_message": "goodbye" }'`
The job should echo that back to you. 

In some environments, the web socket connection will time out and be closed automatically. To avoid that, you can send a JSON string with a "kind" and job name of "keep_alive". Like this: 
`{kind: "keep_alive_click", job_name_with_extension: "keep_alive", keep_alive_value: is_checked}`
This will be processed and won't actually do anything. 

For example, using the Python 2.7 that comes with Ubuntu 16.04, I was able to install:
https://github.com/websocket-client/websocket-client
to add websocket support to Python and then the follow program works to start, and send and receive data from the dexter_message_interface.dde program. 

```py
import websocket
try:
    import thread
except ImportError:
    import _thread as thread
import time

def on_message(ws, message):
    print(message)

def on_error(ws, error):
    print(error)

def on_close(ws):
    print("### closed ###")

def on_open(ws):
    def run(*args):
        for i in range(3):
            time.sleep(1)
            ws.send("{\"job_name_with_extension\": \"dexter_message_interface.dde\", \"ws_message\": \"message %d\" }" % i)
            time.sleep(3)
        ws.close()
        print("thread terminating...")
    thread.start_new_thread(run, ())


if __name__ == "__main__":
    #websocket.enableTrace(True)
    ws = websocket.WebSocketApp("ws://192.168.1.142:3001",
                              on_message = on_message,
                              on_error = on_error,
                              on_close = on_close)
    ws.on_open = on_open
    ws.run_forever()
````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 18:48](https://github.com/HaddingtonDynamics/Dexter/issues/60#issuecomment-722569650):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/60)


-------------------------------------------------------------------------------

# [\#59 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/59) `closed`: Track and return settings of FPGA registers

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-02-19 17:23](https://github.com/HaddingtonDynamics/Dexter/issues/59):

There is currently no way for a control program (like DDE) to know how each of the registers in the FGPA has been set. Many (most) of them are write only, and so DexRun firmware can not query those registers and return their current setting. Also, the default setting of the registers might change, and therefor it can be impossible to know how a register is set unless the firmware or control program has set them. 

Even if they have been set, or if the default settings are moved into the firmware, we do not currently "shadow" or track the last known setting of that register. Adding this functionality will require serious work. 

Finally, some means of returning those settings is necessary. Probably a "fake" JSON file returned via read_from_robot via a "#" name like we did for #XYZ would work and be easy to parse by the controller. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-21 19:20](https://github.com/HaddingtonDynamics/Dexter/issues/59#issuecomment-523611555):

@JamesWigglesworth we really need to know which registers are important for this functionality, to give us a starting point.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-10-14 17:34](https://github.com/HaddingtonDynamics/Dexter/issues/59#issuecomment-541813947):

Added in 
https://github.com/HaddingtonDynamics/Dexter/commit/31c1e41f59eb86452bd60402ce426722c248e1ff

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 18:04](https://github.com/HaddingtonDynamics/Dexter/issues/59#issuecomment-722544830):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/59)

#### <img src="https://avatars0.githubusercontent.com/u/53804153?v=4" width="50">[RonChauffe](https://github.com/RonChauffe) commented at [2020-11-05 18:13](https://github.com/HaddingtonDynamics/Dexter/issues/59#issuecomment-722549789):

Please fix and stop this repeated email issue. 

> On Nov 5, 2020, at 12:05 PM, JamesNewton <notifications@github.com> wrote:
> 
> ﻿
> Kamino cloned this issue to HaddingtonDynamics/OCADO
> 
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub, or unsubscribe.


-------------------------------------------------------------------------------

# [\#58 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/58) `open`: Windows 8 / 10 sometimes can't browse SAMBA share
**Labels**: `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-02-18 23:18](https://github.com/HaddingtonDynamics/Dexter/issues/58):

We hoped that the new Xilinux / Lubuntu 16.04 image would resolve this issue, but it appears to still be a problem for some users.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-18 23:20](https://github.com/HaddingtonDynamics/Dexter/issues/58#issuecomment-464919564):

This might apply, but I think the version of SMB used in 16.04 is beyond 1.0, and the share still fails to load even if you directly point to it. 
http://wdc.custhelp.com/app/answers/detail/a_id/20736/~/how-to-enable-smb-1.0%2Fcifs-file-sharing-support-on-windows-10

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-18 23:23](https://github.com/HaddingtonDynamics/Dexter/issues/58#issuecomment-464920009):

It may be that it still works but you have to do it via "Add a network location".
https://www.techrepublic.com/article/how-to-connect-to-linux-samba-shares-from-windows-10/

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-18 23:41](https://github.com/HaddingtonDynamics/Dexter/issues/58#issuecomment-464922921):

Enabling SMB 1.0 client support in Windows may be the answer. That and a few other possible issues are listed here:
https://social.technet.microsoft.com/Forums/en-US/e43bdd35-6dc6-4182-b7a4-1b77cb7fc16a/following-upgrade-to-windows-10-nas-unit-does-not-show-under-quotnetworkquot?forum=win10itpronetworking

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 17:55](https://github.com/HaddingtonDynamics/Dexter/issues/58#issuecomment-722539782):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/58)


-------------------------------------------------------------------------------

# [\#57 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/57) `closed`: Dexter ethernet adapters all have the same MAC address

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-02-11 01:30](https://github.com/HaddingtonDynamics/Dexter/issues/57):

The zedboard which is Dexters controller implements the ethernet interface hardware in the FPGA chip. Since the FPGA is loaded from the bit file on the sd card image, they all have the same hardware MAC address. 
[^](https://forums.xilinx.com/t5/Embedded-Linux/Perm-changing-the-MAC-address/m-p/61507/highlight/true#M1938) Technically, the MAC is loaded from the EEPROM, but that is loaded from the bit file, so... 

This is not an issue if a USB WiFi dongle is used because the external dongle will have it's own MAC address. As #51 is resolve, that is the better option for multi-robot networking.

This is not an issue if a single Dexter is being connected [directly to a PC](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#connection) as there is no other address to conflict. 

This only becomes an issue when multiple Dexters are connected via CAT 5 to a single router. Although routers should be able to manage the rare case of duplicate MAC addresses, they do not. [^](https://serverfault.com/questions/462178/duplicate-mac-address-on-the-same-lan-possible) [^](https://superuser.com/questions/17696/what-happens-when-two-computers-on-the-same-network-have-the-same-mac-address)

If you need multiple Dexters on one CAT5 ethernet, you will need to edit the interfaces file anyway to change the default [fixed IP address](https://github.com/HaddingtonDynamics/Dexter/issues/37#issuecomment-427994971), or edit for DHCP access so the MAC address can be edited at the same time.

To change the address, edit the /etc/network/interfaces file and add a line:
````
hwaddress ether 00:5D:03:01:02:03
````
substituting different values for the last few numbers. To avoid accidentally crashing with another ventors MAC address, one should probably start the address with one of the Xilinx assigned MAC ranges:<br>
http://www.adminsub.net/mac-address-finder/xilinx


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-11 01:48](https://github.com/HaddingtonDynamics/Dexter/issues/57#issuecomment-462202252):

See also

http://zedboard.org/content/mac-address

http://zedboard.org/content/passing-mac-address-kernel-device-tree-blob

It might be possible to generate a better MAC address from the serial number on the Zynq chip<br>
https://www.xilinx.com/support/answers/40856.html

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-07 17:29](https://github.com/HaddingtonDynamics/Dexter/issues/57#issuecomment-519194429):

The problem with AR# 40856 linked above is that it requires the development system to work. Instead, we should start assigning our own serial numbers to Dexters as they are built and then add a script that uses that serial number to set the MAC. If the serial # is set in the Defaults.make_ins file, RunDexRun script can read it out and set the MAC before it starts DexRun

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-09 06:10](https://github.com/HaddingtonDynamics/Dexter/issues/57#issuecomment-519791953):

Commit 48867f3a0da662c892e8c28c46151c0dce3b4d23 attempts to resolve this issue by getting a serial number from the Defaults.make_ins file and converting it to a mac address, then editing the mac addresses in the /etc/network/interfaces file to update those for the next restart. 

https://github.com/HaddingtonDynamics/Dexter/commit/48867f3a0da662c892e8c28c46151c0dce3b4d23

Please note all the requirements for that to work.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-15 20:45](https://github.com/HaddingtonDynamics/Dexter/issues/57#issuecomment-521790982):

The best way to resolve this is just to use a WiFi adapter as they all have their own mac addresses AND you can get as many Dexters as you like on your local network AND they all have internet connections for e.g. ntp time, remote operation, etc... See:
https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#wifi

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-30 05:25](https://github.com/HaddingtonDynamics/Dexter/issues/57#issuecomment-526460546):

Scratch that... for some strange reason, the WiFi adapter ALSO has the hwaddress set for the CAT5 adapter! (???)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-29 23:05](https://github.com/HaddingtonDynamics/Dexter/issues/57#issuecomment-665974636):

The existing RunDexRun is using the BASH printf to convert the serial number to a hexadecimal MAC address. Unfortunately, the BASH printf, unlike real printf, interprets any number starting with a 0 as being an octal number (rather than decimal) and so any serial number with an 8 or a 9 in any digit results in an error and the MAC is not made unique. e.g. DEX-000038 or 39 or 18 or 19 or 28 or 29 will all have the same MAC. 

The problem, and solution are documented here:
https://stackoverflow.com/a/11804275/663416

This wasn't noticed because only 2 out of 10 robots made so far would have the problem, and we weren't checking the mac address on every robot, and none of the test values I put in happened to have an 8 or 9 /and/ also leading zeros. Great catch @kgallspark ! And also, "really bash? really?"

To fix, edit RunDexRun and change line 32 from:
`mac=$(printf "%06x\n" $dexserial ) `
to 
`mac=$(printf "%06x\n" $(( 10#$dexserial )) ) `

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-29 23:18](https://github.com/HaddingtonDynamics/Dexter/issues/57#issuecomment-665978952):

Closed via
https://github.com/HaddingtonDynamics/Dexter/commit/eb35d50ae94b744fc3401cad0da61355331b2004

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 17:07](https://github.com/HaddingtonDynamics/Dexter/issues/57#issuecomment-722510748):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/57)


-------------------------------------------------------------------------------

# [\#56 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/56) `closed`: Docs: missing motor control PDF

#### <img src="https://avatars2.githubusercontent.com/u/504782?v=4" width="50">[Rinat Abdullin](https://github.com/abdullin) opened issue at [2019-02-03 10:10](https://github.com/HaddingtonDynamics/Dexter/issues/56):

[Readme](https://github.com/HaddingtonDynamics/Dexter/blob/master/Hardware/README.md) in the Hardware section mentions schematics for the motor control, however the PDF itself is missing from the folder.

Would it be possible to add the latest version there?

PS: Thanks a lot for sharing your work as open source! It is very inspiring.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-03 23:28](https://github.com/HaddingtonDynamics/Dexter/issues/56#issuecomment-460099189):

Thanks for noticing! No idea why that was deleted. Restored at: https://github.com/HaddingtonDynamics/Dexter/commit/4cb5bd88470b6e53570f07e47927808611bdabac


-------------------------------------------------------------------------------

# [\#55 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/55) `closed`: Implement a WebSocket server

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) opened issue at [2019-01-31 10:05](https://github.com/HaddingtonDynamics/Dexter/issues/55):

There is the raw socket server on port 50000, but web applications (browser JavaScript) are not able to use raw sockets. Therefore, I recommend implementing a WebSocket server.

There are a couple of ways to do this:
- Use [this file](https://github.com/Kenny2github/scratch-dexter/blob/master/httpd.js) (with the addresses changed) as a proxy to the raw socket
  - This is easy to do, but it makes it harder to backport (which is a concern on the Dexters we have). That file is a node.js file; that means node.js has to come prebundled. It is hard to connect Dexter to the Internet, and without internet it can only serve, making it virtually impossible to send a complete node.js implementation
- Natively implement a WebSocket server in C or Python (both of which come with it already)
  - This is harder to do (the WebSocket protocol is very big!) but is easier to backport - all that needs to be sent is a couple of files, which can pretty much be done even without Internet (temporary server, receive & write, done).

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-31 18:00](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-459443524):

We've already implemented a WebSocket server using Node.js. It's great to be able to work with the robot via a browser, but the speed of WebSockets is less than what we hoped for in a remote control situation, which was our main goal. 
https://github.com/HaddingtonDynamics/Dexter/wiki/nodejs-webserver
We also linked to your scratch extensions from this page and they are VERY appreciated. We hope to make further use of the scratch system in the near future.

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-02-01 06:18](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-459619312):

Is such a server built into Dexter in newer releases? That's the more important part.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-06 17:30](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-461112571):

Great question. Yes, I plan on adding the one shown here:
https://github.com/HaddingtonDynamics/Dexter/wiki/nodejs-webserver#a-node-js-websocket-server
But I want to make sure that will work for your scratch stuff.

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-02-06 20:21](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-461172851):

I mean, as long as there's something running on Dexter itself that obeys the WebSocket protocol, it'll work. And in the long run, whether it's easy to backport is of lower priority - I mean, I don't use the same Dexter every time I test and we seem to build new ones more than just once-off.

Actually, is there a way to update Dexter's firmware without rebuilding? That might prove useful later on.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-06 21:19](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-461191477):

@Kenny2github, when you say "rebuilding" do you mean the `./pg` compilation of DexRun.c? No. In the Linux world, distribution of source and local compilation is the standard. Only in Windows / Mac worlds are binaries the expected distributable. However, the current DexRun supports writing the DexRun.c to the robot via the socket interface, and future versions will support running shell scripts, so the entire update process can happen from DDE without the user having to know what is happening. #20 is the relevant discussion there. 

@cfry It dawns on me that the "Run Engine" you are working on in DDE is the perfect candidate for supporting this websocket interface. As you can see, the code is NOT complex. 
https://github.com/HaddingtonDynamics/Dexter/wiki/nodejs-webserver#a-node-js-websocket-server

Also, it just dawned on me that as per:
https://github.com/HaddingtonDynamics/Dexter/wiki/Scratch-extension
Scratch actually needs a proxy running on the PC where the scratch programming is being done, NOT necessarily on the Dexter, unless the Dexter IS the PC... We have firefox on the new Dexter image... I'll have to try scratch on Dexter.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-07 00:37](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-461245470):

I can't seem to get adobe-flash to install... @Kenny2github is there a chance of your extension supporting Scratch3 (which as I understand it, does NOT require flash)? Actually, I can't even seem to get that to load in the FireFox on Dexter. It appears to be quite out of date, but I can't update it via the OS. 
apt update doesn't see it as out of date. I will have to look into this more later.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-11 01:06](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-510285942):

Scratch 3 is now supported, see wiki.

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-07-11 03:21](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-510313298):

Scratch 3 is supported, but the WS server is still required and as far as I can tell still not built in. And installing node is difficult when you can't connect Dexter to the Internet

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-11 03:25](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-510313989):

Ah. I believe the issue is that the websocket server must be on the same IP as Scratch3 is running. e.g. if you run a websocket proxy on Dexter, and run Scratch in a browser on a PC, then when you try to connect to the Dexter from the browser, it complains about the security issue. Am I wrong about that?

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-07-12 06:15](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-510760916):

You're probably (I haven't been able to test anything with a WS server on Dexter itself because we can't actually connect Dexter to the Internet and therefore can't install node and can't run the server) not wrong , CORS is no joke, but the simple fix is to add (somehow) a response header in the WS handshake like `Access-Control-Allow-Origin: *` so that browsers don't complain.

Currently the extension expects the server to be on `localhost:3000` but if the WS server (with the header) was built in it would be simple enough to ask the user for Dexter's IP and connect to `<that>:3000` or something, thus massively simplifying the process of using the extension (as installing node is complicated at best, and it's required for the server).

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-12 16:23](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-510947965):

As I understand it, that response header must be sent from the web server, e.g. from the scratch website. It's goal is to keep malicious code from running based on invalid content. So if a hacker wanted to attack your browser, and could get a <script src= tag imbedded in content on a good server, then point the src to his "evil" server, the browser would reject it. If it were possible for him to add `Access-Control-Allow-Origin:` to his own "evil" server, then he would do it. Instead, the "good" server has to say "I trust the evil server" by putting the header in the original response. I may be wrong, as I'm not an expert, but I think that's how that works.

https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-07-14 07:17](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-511179687):

No, that's not how it works, at least not from my experimentation. Here's what I did:

First, I ran the Python `http.server` module directly, which runs a simple file-based server (though the response text is irrelevant here). I then went to http://example.com and put this in the console:
```js
var xhr = new XMLHttpRequest();
xhr.open('GET', 'http://' + my_computer_ip);
xhr.send()
```
And the response in the console was an error message saying `Access to XMLHttpRequest at 'http://(my ip)/' from origin 'http://example.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.`

I then set up a tiny Python server which just responds with a 200 code, an `Access-Control-Allow-Origin: *` header, and then the text `Hello World!`:
```python
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
  def do_GET(self):
    self.send_response(200)
    self.send_header('Access-Control-Allow-Origin', '*')
    self.end_headers()
    self.wfile.write(b'Hello World!')

httpd = HTTPServer(('0.0.0.0', 80), Handler)
while 1:
  try:
    httpd.handle_request()
  except KeyboardInterrupt:
    break
```
After running that, I ran the JS code again, and it came through just fine: `XHR finished loading: GET "http://(my ip)/".`
And the response was properly set:
![image](https://user-images.githubusercontent.com/28599280/61180514-10228800-a64a-11e9-95c2-bc0937e503bf.png)

So I'm pretty sure that the server whose resource is being requested is the one responsible for adding the header, not the server whose content's JS is sending the request, and therefore if a WS server was built into Dexter it would only need to send the header to be usable by the Scratch extension, no matter where it's hosted.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-22 22:41](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-513982136):

Ok, I've [updated the httpd.js server](https://github.com/HaddingtonDynamics/Dexter/wiki/nodejs-webserver/_compare/ac894e0c5bde84be5ca19a53181cce0bf29972a0...59e786447f33dd5f472d82b4dea8acbdfe75492f) so that it returns that header. 

What do I need to do to test it?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-22 23:09](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-513988547):

I've updated the httpd.js proxy server on my robot and tested it with this page:
http://www.massmind.org/techref/robot/Dexter.html
but it turns out that works with or without the extra header! 

What do I need to do to test this with your scratch3 system?

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-07-23 12:29](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-514188836):

I am an idiot.

CORS doesn't apply to WebSockets, only to HTTP requests. Though the WS handshake follows the HTTP protocol, the scheme is still ws:// and so CORS doesn't apply.
That being said, for any website to access files from Dexter through that server, it does need the header, so your change was warranted.

I haven't made the necessary changes to be able to test this yet, but I will at some point during the week (though I'm on vacation, so no guarantees).

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-05 22:38](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-518427647):

Hey @Kenny2github , how hard would it be to just install your extended version of Scratch 3 on Dexter? So that if you hit Dexters IP address with your browser, you would get Scratch? Is it just installing:
https://github.com/Kenny2github/scratch-gui
?
Or does that also then install a ton of dependencies? I'm trying to get a sense of the total "hard drive" (SD Card) space required. If it's not that much, it might just be worth adding it to the image. Especially if we could have a welcome page and then your Scratch is one option.

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-08-07 11:04](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-519049902):

Two problems with that:
1. Too big. Total size on my install is 2.49 GiB.
2. There still needs to be some sort of server running. (Does the samba folder work for that?)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-07 16:56](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-519182300):

Hmm... 2 and a half gigs is probably more than we want to carry around on every image. How hard is it to install it on demand and remove it when not wanted? E.g. is there an easy command or two that spins it up? And can we reliably delete it and recover the space? The server in the /srv/samba/share/www folder can be spun up for that, I'm sure.

#### <img src="https://avatars2.githubusercontent.com/u/28599280?v=4" width="50">[Ken](https://github.com/Kenny2github) commented at [2019-08-08 04:40](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-519360374):

Turns out I lied - the size of the "master" branch of my fork is 2.49 GB but the size of the actual built files served to the client totals only 30 MiB, which I think is suitable.

Installing Scratch on Dexter - now quite feasible. (I think there's already a server for samba share?) Just copy all the files in https://github.com/Kenny2github/scratch-gui/tree/gh-pages into some folder in /srv/samba/share/www.
Using it with Dexter - still needs a WS server... JavaScript can't connect to raw sockets, period. Best case scenario would be for DexRun.c to run the WS server on some other port than the raw socket port, perhaps by using [libwebsockets](https://libwebsockets.org/).

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-21 19:14](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-523609527):

Following Kenny's directions above has resulted in a working copy of scratch AND a web socket server being a regular part of Dexter. See the files in /srv/samba/share/www for the socket server and follow his directions to implement Scratch. The next standard image has all that (including scratch) on it. There are some issues (e.g. you can't save programs) but those should be addressed in a separate issue as this is for the socket server and that works. 
https://github.com/HaddingtonDynamics/Dexter/blob/StepAngles/Firmware/www/httpd.js

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-12-03 01:41](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-560959272):

I've also added a web socket interface proxy for the onboard "job engine" aka dde running on Dexter. This is separate from the web socket proxy to DexRun firmware:
https://github.com/HaddingtonDynamics/Dexter/commit/8d28d192edcce2aaf3c33dd5350d06d0ae31ca0f

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-12 00:53](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-597952264):

One small change is recommended when running Kenny's scratch from Dexter: In the lib.min.js file, find the line: `this._ws = new WebSocket('ws://192.168.1.142:3000');` and change it to `this._ws = new WebSocket('ws://'+window.location.hostname+':3000');`. This allows scratch to find Dexter no matter what it's IP address happens to be.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 01:13](https://github.com/HaddingtonDynamics/Dexter/issues/55#issuecomment-722062934):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/55)


-------------------------------------------------------------------------------

# [\#54 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/54) `closed`: FPGA outputs to motors ....  can servos be used ?

#### <img src="https://avatars3.githubusercontent.com/u/27163362?v=4" width="50">[Cinternational   Odogs  ZeroVectorFoundation  WFTelectronics](https://github.com/odogs) opened issue at [2019-01-27 19:18](https://github.com/HaddingtonDynamics/Dexter/issues/54):

I am interested in using servo motors rather than stepper motors.   

in particular .... the Odrive    https://odriverobotics.com/

Odrive supports step/direction motor control ( reluctantly )
other control methods are available ....  https://docs.odriverobotics.com/interfaces

Best

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-28 04:24](https://github.com/HaddingtonDynamics/Dexter/issues/54#issuecomment-457995190):

The current FPGA programming produces step and direction signals, so that would be the best bet for easily replacing the steppers were odrives. 

Reprogramming the FPGA to produce other control signals is technically possible, but very difficult.  At this time, the Viva FPGA design software we use is only available on a very limited basis to experienced digital logic engineers. We hope to change that in the future, as funding allows.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 17:06](https://github.com/HaddingtonDynamics/Dexter/issues/54#issuecomment-722510092):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/56)

#### <img src="https://avatars0.githubusercontent.com/u/53804153?v=4" width="50">[RonChauffe](https://github.com/RonChauffe) commented at [2020-11-05 18:11](https://github.com/HaddingtonDynamics/Dexter/issues/54#issuecomment-722548856):

Please fix and stop this repeated email issue. 

> On Nov 5, 2020, at 11:07 AM, JamesNewton <notifications@github.com> wrote:
> 
> ﻿
> Kamino cloned this issue to HaddingtonDynamics/OCADO
> 
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub, or unsubscribe.


-------------------------------------------------------------------------------

# [\#53 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/53) `closed`: 'Left' configs no longer work

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) opened issue at [2019-01-26 22:19](https://github.com/HaddingtonDynamics/Dexter/issues/53):

Joint 5 appears to be off by 180° in left configs.
Other configs may not be working either. 
Mostly likely broken in both DDE and DexRun inverse kinematics.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-01-27 18:10](https://github.com/HaddingtonDynamics/Dexter/issues/53#issuecomment-457940475):

IS this something that happened in the latest DDE release,
or has it been there for a while?

On Sat, Jan 26, 2019 at 5:19 PM JamesWigglesworth <notifications@github.com>
wrote:

> Joint 5 appears to be off by 180° in left configs.
> Other configs may not be working either.
> Mostly likely broken in both DDE and DexRun inverse kinematics.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/53>, or mute the
> thread
> <https://github.com/notifications/unsubscribe-auth/ABITfWdI0ygnYJ2B3fXvFZYBMKja9nE2ks5vHNRegaJpZM4aUavb>
> .
>

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) commented at [2019-01-27 19:45](https://github.com/HaddingtonDynamics/Dexter/issues/53#issuecomment-457947877):


    
I think it's been in there for a while.My guess is ever since we had the confusion over which rotation direction was positive.

Sent via the Samsung Galaxy Note® 4, an AT&T 4G LTE smartphone

-------- Original message --------
From: cfry <notifications@github.com> 
Date: 1/27/19  10:10 AM  (GMT-08:00) 
To: HaddingtonDynamics/Dexter <Dexter@noreply.github.com> 
Cc: JamesWigglesworth <jameswigglesworth@hdrobotic.com>, Author <author@noreply.github.com> 
Subject: Re: [HaddingtonDynamics/Dexter] 'Left' configs no longer work (#53) 

IS this something that happened in the latest DDE release,


or has it been there for a while?





On Sat, Jan 26, 2019 at 5:19 PM JamesWigglesworth <notifications@github.com>


wrote:





> Joint 5 appears to be off by 180° in left configs.


> Other configs may not be working either.


> Mostly likely broken in both DDE and DexRun inverse kinematics.


>


> —


> You are receiving this because you are subscribed to this thread.


> Reply to this email directly, view it on GitHub


> <https://github.com/HaddingtonDynamics/Dexter/issues/53>, or mute the


> thread


> <https://github.com/notifications/unsubscribe-auth/ABITfWdI0ygnYJ2B3fXvFZYBMKja9nE2ks5vHNRegaJpZM4aUavb>


> .


>






—
You are receiving this because you authored the thread.
Reply to this email directly, view it on GitHub, or mute the thread.

{"api_version":"1.0","publisher":{"api_key":"05dde50f1d1a384dd78767c55493e4bb","name":"GitHub"},"entity":{"external_key":"github/HaddingtonDynamics/Dexter","title":"HaddingtonDynamics/Dexter","subtitle":"GitHub repository","main_image_url":"https://github.githubassets.com/images/email/message_cards/header.png","avatar_image_url":"https://github.githubassets.com/images/email/message_cards/avatar.png","action":{"name":"Open in GitHub","url":"https://github.com/HaddingtonDynamics/Dexter"}},"updates":{"snippets":[{"icon":"PERSON","message":"@cfry in #53: IS this something that happened in the latest DDE release,\nor has it been there for a while?\n\nOn Sat, Jan 26, 2019 at 5:19 PM JamesWigglesworth \u003cnotifications@github.com\u003e\nwrote:\n\n\u003e Joint 5 appears to be off by 180° in left configs.\n\u003e Other configs may not be working either.\n\u003e Mostly likely broken in both DDE and DexRun inverse kinematics.\n\u003e\n\u003e —\n\u003e You are receiving this because you are subscribed to this thread.\n\u003e Reply to this email directly, view it on GitHub\n\u003e \u003chttps://github.com/HaddingtonDynamics/Dexter/issues/53\u003e, or mute the\n\u003e thread\n\u003e \u003chttps://github.com/notifications/unsubscribe-auth/ABITfWdI0ygnYJ2B3fXvFZYBMKja9nE2ks5vHNRegaJpZM4aUavb\u003e\n\u003e .\n\u003e\n"}],"action":{"name":"View Issue","url":"https://github.com/HaddingtonDynamics/Dexter/issues/53#issuecomment-457940475"}}}

[

{

"@context": "http://schema.org",

"@type": "EmailMessage",

"potentialAction": {

"@type": "ViewAction",

"target": "https://github.com/HaddingtonDynamics/Dexter/issues/53#issuecomment-457940475",

"url": "https://github.com/HaddingtonDynamics/Dexter/issues/53#issuecomment-457940475",

"name": "View Issue"

},

"description": "View this Issue on GitHub",

"publisher": {

"@type": "Organization",

"name": "GitHub",

"url": "https://github.com"

}

}

]

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) commented at [2019-01-28 02:04](https://github.com/HaddingtonDynamics/Dexter/issues/53#issuecomment-457977733):

Bug fixed.
Will be in DDE release 3.0.8 and later.

To test here's a position and direction that will work with all combinations of configs:
[0, 0.3, 0.4], [0, 0, -1]

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 01:12](https://github.com/HaddingtonDynamics/Dexter/issues/53#issuecomment-722062511):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/54)


-------------------------------------------------------------------------------

# [\#52 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/52) `open`: SD Card difficult to insert and remove
**Labels**: `Hardware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-01-22 17:42](https://github.com/HaddingtonDynamics/Dexter/issues/52):

Because the SD card slot on the [microzed PCB](https://github.com/HaddingtonDynamics/Dexter/wiki/MicroZed) is on the back side, and the stepper motor drivers on the motor board are right behind it, inserting and removing the [SD card](https://github.com/HaddingtonDynamics/Dexter/wiki/SD-Card-Image) can be very difficult. 

- If the fan has been mounted directly over the stepper motor drivers, it must be removed for access. A fan mounted on the inside of the skin or otherwise placed out of the way and then ducted to the motor drivers is better. 

- The connector pads on the SD Card must be oriented facing the user, opposite the motor drivers. 

- This SD Card Tool can be 3D printed to help hold the card in position for insertion. It rests on the edge of the terminal blocks for proper alignment. Because the model is made to the exact dimensions of the card, and 3D printer filament often spreads, you may need to scrape out the slot a little after printing. If available, a fine drill (around 0.035" diameter) can be used to drill out the base of the slot to accommodate the slightly wider base of the SD Card. 
[SD_Card_Tool.zip](https://github.com/HaddingtonDynamics/Dexter/files/2783859/SD_Card_Tool.zip)


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-03-05 04:58](https://github.com/HaddingtonDynamics/Dexter/issues/52#issuecomment-469537909):

Another possibility is making SD Card image updates possible without removing the SD Cards. It should be possible to use a 16GB SD Card and partition the unused 8GB of it into a duplicate of the standard 8GB image. Then, a new image could be downloaded and written to that partition. Once complete, the new partition could be marked as the boot partition and the system restarted. 

https://askubuntu.com/questions/491082/steps-to-create-dd-image-file-from-usb-and-restore-image-to-a-different-usb

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-03-05 05:23](https://github.com/HaddingtonDynamics/Dexter/issues/52#issuecomment-469542673):

The size of the downloaded .img file is a serious problem in any case.  Being able to download the /difference/ between two images might decrease the size and speed things up. There are programs that can compute the difference between large binary files. For example:

https://github.com/jmacd/xdelta/blob/wiki/CommandLineSyntax.md
To create a patch file with the difference between the old and new versions: 
`xdelta -e -s old_file new_file difference_file`
To apply that patch to an old file to make the new one: 
`xdelta -d -s old_file difference_file new_file`

The downside to this is that it would require more than a 16 GB SD Card; at least 32 GB and probably 64. You would need a working drive to store the original .img file (8GB) for the hard drive, and the patch file (?GB), and then the resulting new .img file (8GB) which would then be used to create the new partition. 

I'm not sure how useful this is. Testing show that a binary diff of two images in which the only change is to a couple of small text files results in a patch which is almost 1MB in size. It would be far more efficient and safer to just download the text files. The binary diff of the Xillinux 12 version with the new 16.04 version was nearly 3GB and since very large updates like that will be rare, it seems less useful.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-03-05 19:15](https://github.com/HaddingtonDynamics/Dexter/issues/52#issuecomment-469820545):

I like the idea of being able to keep your old version
while you download a new version
to your SD card that's in the robot.
Then if the new image screws up, you can
revert to the old image.
But as JamesN says, that means having
a significantly larger SD card.
https://www.google.com/search?q=Amazon+16+GByte+SD+card&spell=1&sa=X&ved=0ahUKEwj0sM7L2uvgAhWlY98KHeXCD9IQBQgrKAA&biw=973&bih=531&dpr=2
says 16GByte SD card is only $5 quantity one.
64Gbyte is $11.55.
Making the update process easy is indeed important.

On Tue, Mar 5, 2019 at 12:23 AM JamesNewton <notifications@github.com>
wrote:

> The size of the downloaded .img file is a serious problem in any case.
> Being able to download the /difference/ between two images might decrease
> the size and speed things up. There are programs that can compute the
> difference between large binary files. For example:
>
> https://github.com/jmacd/xdelta/blob/wiki/CommandLineSyntax.md
> To create a patch file with the difference between the old and new
> versions:
> xdelta -e -s old_file new_file difference_file
> To apply that patch to an old file to make the new one:
> xdelta -d -s old_file difference_file new_file
>
> The downside to this is that it would require more than a 16 GB SD Card;
> at least 32 GB and probably 64. You would need a working drive to store the
> original .img file (8GB) for the hard drive, and the patch file (?GB), and
> then the resulting new .img file (8GB) which would then be used to create
> the new partition.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/52#issuecomment-469542673>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITfZcOZaZEtPmFpf_JQzgcNPR213v4ks5vTf9egaJpZM4aNLnZ>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-03-06 00:37](https://github.com/HaddingtonDynamics/Dexter/issues/52#issuecomment-469917476):

Based on the advice of a couple facebook friends, it looks like it's possible to use the `apt` system to just install updates which are developed by packaging up the changed files as if they were a regular software program. e.g. you could `apt-get update` and our files would be downloaded, compiled and installed automatically, accomplishing exactly what we do manually. That update command could even be triggered periodically. Or via #20 .

From the apt-get update manual: " update is used to resynchronize the package index files from their
sources. The indexes of available packages are fetched from the location(s) specified in /etc/apt/sources.list. "

Building a package is complex, but not impossible. 
https://debian-handbook.info/browse/stable/sect.building-first-package.html

This video breaks the process down into the simplest steps for making an application. It may be that we can make a "Dexter Update" application which is installed with scripts that then copy files into the other places they need to be. 
https://www.youtube.com/watch?v=nhoRyd2CEVs

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-05-03 19:44](https://github.com/HaddingtonDynamics/Dexter/issues/52#issuecomment-489217271):

Multiple SD Card extension cables have been tried, but all are either mechanically unsuited (too wide at the point the go into the existing socket, or poor mechanical interface at the extended socket) or poor quality. It may be that soldering wires onto the back of the existing connector and running them out to a sub PCB may be an option. Perhaps a better cable can be found. 

https://www.adafruit.com/product/3688 is too wide at the end that plugs into the MicroZed card.

https://www.ebay.com/p/18023470718?iid=131565092246 fits well, but the connector is the type where you lay the card in the tray and then close the lid, so it really needs to be mounted flat.

https://www.robotdigg.com/product/1119/15cm-SD-or-TF-card-extender-cable-for-3D-printing Has not been tried.

Another issue is finding a good place to mount the extended socket. Perhaps on the bottom inside of a new skin segment? See: "Skins" Issue #4

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 01:09](https://github.com/HaddingtonDynamics/Dexter/issues/52#issuecomment-722061638):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/53)


-------------------------------------------------------------------------------

# [\#51 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/51) `closed`: Dexter doesn't support a WiFi adapter

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-01-22 01:55](https://github.com/HaddingtonDynamics/Dexter/issues/51):

In the past, Dexter was unable to support a USB WiFi adapter for RF networking, because the driver would not load on the version 12 operating system. 

A new Ubuntu 16.04 image being completed to close #25 might allow a WiFi adapter to be added and work.

There appears to be a special adapter designed for the microzed board:
http://www.zedboard.org/product/wilink-8-adaptor

However, if a USB WiFi adapter is preferred, the current placement of the fan, at the bottom of the microzed board, blocks all the USB connectors (and the sd card). Moving the fan out to the skin and ducting the air to the stepper motor drivers would give us the physical access we need the USB hub for connecting peripherals to Dexter.



#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-01-22 19:52](https://github.com/HaddingtonDynamics/Dexter/issues/51#issuecomment-456538976):

This looks much bigger than a wifi "nub".
Does it have the same functionality?
The above product costs $34.
http://www.zedboard.org/sites/default/files/product_briefs/PB-AES-PMOD-WILINK8-G-V1.pdf

Compare to:
https://www.amazon.com/Edimax-EW-7811Un-150Mbps-Raspberry-Supports/dp/B003MTTJOY
for $10.

On Mon, Jan 21, 2019 at 8:55 PM JamesNewton <notifications@github.com>
wrote:

> In the past, Dexter was unable to support a USB WiFi adapter for RF
> networking, because the driver would not load on the version 12 operating
> system.
>
> A new Ubuntu 16.04 image being completed to close #25
> <https://github.com/HaddingtonDynamics/Dexter/issues/25> might allow a
> WiFi adapter to be added and work.
>
> There appears to be a special adapter designed for the microzed board:
> http://www.zedboard.org/product/wilink-8-adaptor
>
> However, if a USB WiFi adapter is preferred, the current placement of the
> fan, at the bottom of the microzed board, blocks all the USB connectors
> (and the sd card). Moving the fan out to the skin and ducting the air to
> the stepper motor drivers would give us the physical access we need the USB
> hub for connecting peripherals to Dexter.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/51>, or mute the
> thread
> <https://github.com/notifications/unsubscribe-auth/ABITfQuKMdzvLr4QUGLG6dG68YIz0xJjks5vFm-qgaJpZM4aLyKA>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-23 05:33](https://github.com/HaddingtonDynamics/Dexter/issues/51#issuecomment-456676095):

I think trying a cheap adapter first is a great idea... I'm not sure why they have that specific adapter...

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-01 19:53](https://github.com/HaddingtonDynamics/Dexter/issues/51#issuecomment-459847278):

Resolved with the upgraded OS #25

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-27 02:20](https://github.com/HaddingtonDynamics/Dexter/issues/51#issuecomment-515644076):

One issue with WiFi adapters is that the DHCP protocol will assign an IP on the local router and it's difficult to find out which IP was assigned. I remembered that there was a javascript page that could decode morse code:
https://www.bennadel.com/resources/demo/morse_code/ 
https://www.bennadel.com/blog/2267-decoding-morse-code-with-javascript.htm 
 
Take the keyboard events off that and add processing from the camera:
https://googlechrome.github.io/samples/image-capture/grab-frame-take-photo.html 
 
Accessing the pixels in the picture isn't hard, and you can do a threshold to see if the picture is overall bright (LED on) or dark (LED off).
https://github.com/JamesNewton/AdvancedRoboticsWithJavascript/wiki#image-subtraction-in-a-smartphone-browser 
 
Put that on a public web page (must have HTTPS, not HTTP) and then users can go to the web page, allow access to the camera, hold the camera over the robot, get the web URL decoded, and then click on it to connect directly to the robot!

Users don't even need to know that it's using morse code. But it's also sort of cool that it could decode any message.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-07 17:44](https://github.com/HaddingtonDynamics/Dexter/issues/51#issuecomment-519200173):

Although the wifi adapter does work, it can't be directly plugged into the USB A connector on the MicroZed board because that places it directly over the stepper drivers which get quite hot, causing the adapters to fail. Instead, a short USB A male to USB A female extension cable or small USB hub should be used to bring the port out into cooler air.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-15 20:43](https://github.com/HaddingtonDynamics/Dexter/issues/51#issuecomment-521790310):

For more information, management, etc... see:
https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-Networking#wifi

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-09-23 23:59](https://github.com/HaddingtonDynamics/Dexter/issues/51#issuecomment-534330287):

To avoid the heating problems with the little [Edimax-EW-7811Un](https://www.amazon.com/Edimax-EW-7811Un-150Mbps-Raspberry-Supports/dp/B003MTTJOY)  chipset RTL8188CUS
 ( which seems to overheat because it's entirely enclosed in the USB slot ) I got a new adapter which uses the similar RTl8192cu chipset but has a larger body which extends outside the slot. 
(https://www.adafruit.com/product/1012)
It works fine, but I notice that it printed this message to the console when I plugged it in:
`ftlwifi: Firmware rtlwifi/rtl8192cufw_TMSC.bin not available`
And yet it works...

I also tried this one but it doesn't work.
https://www.amazon.com/Panda-300Mbps-Wireless-USB-Adapter/dp/B00EQT0YK2/   
And I about drove myself nuts over the last day and a half trying to get the driver to compile for it.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 01:08](https://github.com/HaddingtonDynamics/Dexter/issues/51#issuecomment-722061247):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/52)


-------------------------------------------------------------------------------

# [\#50 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/50) `closed`: Documentation for Eye Calibration

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) opened issue at [2019-01-20 02:19](https://github.com/HaddingtonDynamics/Dexter/issues/50):

Add doc for when Eye Calibration is needed and how do do it.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-20 02:56](https://github.com/HaddingtonDynamics/Dexter/issues/50#issuecomment-455833240):

It's documented in DDE. Referenced here:
https://github.com/HaddingtonDynamics/Dexter/wiki/Encoder-Calibration

Is there any other way to do it? I mean, outside DDE? Or is there a reason to duplicate the documentation into the WiKi? Or is the documentation in DDE not sufficient? 

Actually.... now you mention it, knowing when that calibration is needed is a tricky point. How DO you know? What are the symptoms that appear that let you know a joint needs to be calibrated? I guess "freakout" is a good one. Perhaps we need a "troubleshooting" list, with symptoms and solutions?

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-01-21 05:51](https://github.com/HaddingtonDynamics/Dexter/issues/50#issuecomment-455955856):

James N,
good point about "how do you know when you need calibration?
Is there some quick automated test we could do
that would tell a user
"um, looks like you need to calibrate your robot by doing ...."
It might even run automatically the first time
a user runs a job on dexter during a dde session.
Like printing out a general "health" report!

On Sat, Jan 19, 2019 at 9:56 PM JamesNewton <notifications@github.com>
wrote:

> It's documented in DDE. Referenced here:
> https://github.com/HaddingtonDynamics/Dexter/wiki/Encoder-Calibration
>
> Is there any other way to do it? I mean, outside DDE? Or is there a reason
> to duplicate the documentation into the WiKi? Or is the documentation in
> DDE not sufficient?
>
> Actually.... now you mention it, knowing when that calibration is needed
> is a tricky point. How DO you know? What are the symptoms that appear that
> let you know a joint needs to be calibrated? I guess "freakout" is a good
> one. Perhaps we need a "troubleshooting" list, with symptoms and solutions?
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/50#issuecomment-455833240>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITfZRTBmDX-cXvx5c5VKOvnr-XBOeOks5vE9r0gaJpZM4aJbon>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-28 23:01](https://github.com/HaddingtonDynamics/Dexter/issues/50#issuecomment-525954680):

The monitor added in recent releases should resolve the "you need to calibrate" issue. When it sees extreme velocities, it will throw an error and DDE can see that and warn the user. @cfry we need to resolve the error handling stuff in DDE to make this work.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:57](https://github.com/HaddingtonDynamics/Dexter/issues/50#issuecomment-722057996):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/50)


-------------------------------------------------------------------------------

# [\#49 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/49) `closed`: Link Length Diagram

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) opened issue at [2019-01-15 18:53](https://github.com/HaddingtonDynamics/Dexter/issues/49):

Need a diagram showing where the link lengths are measured from.
Currently there is only one showing L4 and L5 in DDE.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-01-15 18:58](https://github.com/HaddingtonDynamics/Dexter/issues/49#issuecomment-454509260):

The link length of a link should be the distance
between the pivot points of the
surrounding joints for a link, right?

On Tue, Jan 15, 2019 at 1:53 PM JamesWigglesworth <notifications@github.com>
wrote:

> Need a diagram showing where the link lengths are measured from.
> Currently there is only one showing L4 and L5 in DDE.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/49>, or mute the
> thread
> <https://github.com/notifications/unsubscribe-auth/ABITfbil5Z4ek6vdflcYEmaYjMjE0wpQks5vDiOvgaJpZM4aBlpm>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-28 23:16](https://github.com/HaddingtonDynamics/Dexter/issues/49#issuecomment-525958059):

This is the one that shows L4 / L5 correct?
https://github.com/cfry/dde/blob/master/doc/coor_images/Tooltip_Location.PNG

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:52](https://github.com/HaddingtonDynamics/Dexter/issues/49#issuecomment-722056536):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/49)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:53](https://github.com/HaddingtonDynamics/Dexter/issues/49#issuecomment-722056719):

See Kinematics page in wiki


-------------------------------------------------------------------------------

# [\#48 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/48) `open`: DexRun.c casts a float into an unsigned int
**Labels**: `help wanted`, `invalid`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-01-08 01:40](https://github.com/HaddingtonDynamics/Dexter/issues/48):

[DexRun.c casts a float into an unsigned int](https://github.com/HaddingtonDynamics/Dexter/search?q=%22*%28unsigned+int*%29%26fa2%3B%22&unscoped_q=%22*%28unsigned+int*%29%26fa2%3B%22). This generates the warning: 
````
DexRun.c: In function 'SetParam':
DexRun.c:3868:2: warning: dereferencing type-punned pointer will break strict-aliasing rules [-Wstrict-aliasing]
  unsigned int *uia2 = *(unsigned int*)&fa2;
  ^
DexRun.c:3868:23: warning: initialization makes pointer from integer without a cast [-Wint-conversion]
  unsigned int *uia2 = *(unsigned int*)&fa2;
                       ^
````

To correct this, memcpy can be used:<br>
https://stackoverflow.com/questions/17789928/whats-a-proper-way-of-type-punning-a-float-to-an-int-and-vice-versa

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:51](https://github.com/HaddingtonDynamics/Dexter/issues/48#issuecomment-722056256):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/48)


-------------------------------------------------------------------------------

# [\#47 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/47) `closed`: StartSpeed should never be zero? It will be 0 if set to 1.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2019-01-04 00:34](https://github.com/HaddingtonDynamics/Dexter/issues/47):

Current [code in DexRun.c](https://github.com/HaddingtonDynamics/Dexter/search?q=mapped%5BSTART_SPEED%5D&unscoped_q=mapped%5BSTART_SPEED%5D) is XORing the [StartSpeed](https://github.com/HaddingtonDynamics/Dexter/wiki/set-parameter-oplet) with 1. 

`mapped[START_SPEED]=1 ^ a2;`

[The `^` operator in C is XOR. ](https://en.wikipedia.org/wiki/Bitwise_operations_in_C#Bitwise_operators) so if a 1 is sent as the parameter, the result will be 0. And a 0 will become a 1. Larger values will simple transition to the nearest value. E.g. 5 will become 4 and 4 will be 5. 1000 will become 1001. With larger values the LSB change quickly becomes negligible. 

If I understand correctly, StartSpeed can not be 0 because then the counter in the FPGA will never overflow and the joints won't move. 

My expectation is that the operator used should be [`l` the OR operator](https://en.wikipedia.org/wiki/Bitwise_operations_in_C#Bitwise_operators) so that 1 will become 1 and 0 will become 1. Larger values will only be changed if they are even, and will always become the next higher value. 

The other option is to simply check for zero and always change 0 to 1 without making any other changes.

But before any change is made, we should verify the intent of the current code. Is it just there to try to ensure the value is never zero?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-24 18:14](https://github.com/HaddingtonDynamics/Dexter/issues/47#issuecomment-457300608):

StartSpeed in the FPGA defaults to 500. E.g. putting in 0 makes the speed 500. So reversing those bits, putting in 500, makes the speed 0. Any actual speed must be XOR'd with 500 before being sent to the FPGA. This XOR with 1 was a hold over from a time when the default speed was 1. The FPGA default was changed to 500 and the matching change was not made in DexRun. This has been corrected in:
https://github.com/HaddingtonDynamics/Dexter/compare/SpeedsUpdate#diff-691272021fae98368efb598f8e089c16R3632
on the [SpeedsUpdate](https://github.com/HaddingtonDynamics/Dexter/tree/SpeedsUpdate) branch, along with other improvements / corrections to the speed system. 

Anyone experiencing that problem should try that branch.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:50](https://github.com/HaddingtonDynamics/Dexter/issues/47#issuecomment-722056064):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/47)


-------------------------------------------------------------------------------

# [\#46 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/46) `closed`: txt.string_to_lines fails with 1 char string
**Labels**: `DDE`


#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) opened issue at [2018-12-14 20:39](https://github.com/HaddingtonDynamics/Dexter/issues/46):

This function creates the dxf for drawing a string.
it works for 2 + lengthed strings but not for 1 char strings.
This is a useful function so let Fry know when its fixed
so I can document it.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-24 18:15](https://github.com/HaddingtonDynamics/Dexter/issues/46#issuecomment-457300913):

To clarify, this is a DDE issue, correct?

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-01-24 18:28](https://github.com/HaddingtonDynamics/Dexter/issues/46#issuecomment-457305045):

Yes this is a DDE issue.

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) commented at [2019-01-27 02:07](https://github.com/HaddingtonDynamics/Dexter/issues/46#issuecomment-457882536):

Fixed:
https://github.com/cfry/dde/commit/f4e3ba369fb5c9e285b7836f41795a8c86ecdc8d#diff-0e6dc4fac949e204d6599e0290535e64

Will be in DDE v3.0.8 and later.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:49](https://github.com/HaddingtonDynamics/Dexter/issues/46#issuecomment-722055703):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/46)


-------------------------------------------------------------------------------

# [\#45 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/45) `open`: 30 second move causes socket timeout?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-12-13 22:42](https://github.com/HaddingtonDynamics/Dexter/issues/45):

The socket interface in DexRun.c is set to timeout after 30 seconds and close the interface. If a movement takes longer than 30 seconds, the return status command may not be returned because the connection may be closed. 

Note: The above is a guess based on the source code. It has not been tested or seen at this time. That makes sense because few moves take that long. But if it's possible, then we should look for it.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:48](https://github.com/HaddingtonDynamics/Dexter/issues/45#issuecomment-722055266):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/45)


-------------------------------------------------------------------------------

# [\#44 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/44) `open`: USB Interface?
**Labels**: `communication`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-12-01 05:46](https://github.com/HaddingtonDynamics/Dexter/issues/44):

Could another mode be added to DexRun.c that accepted the same standard command format currently used for the network socket interface, but via the [USB console connection](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-USB-Connection)? Upon connection, the host program (e.g. DDE) could issue commands to `pkill DexRun` then `./DexRun 1 4 0` (where 4 is the serial command mode) and then start communicating with DexRun. The binary return data might be an issue, but it could be translated into hex, or even ascii numbers. The limitation on socket size doesn't apply to a USB connection. 

The advantage of a USB connection is that for a single computer / Dexter com link, there is no issue of IP address or mismatched subnets. 

The disadvantage is that it can be difficult to recognize which USB serial port is Dexter if there are more than one serial device connected. The only information provided by a USB device is the VID (Vendor ID) and PID (Peripheral ID) and the chip used on the MicroZed board is just a standard SciLabs CP2102, which is often used in other USB/serial devices. Changing the VID/PID is possible but would cause the OS to not know what driver to load. Registering a new VID/PID with an OS vendor is a non-starter. Providing a driver that isn't registered is prohibited on later Windows versions. The best way to id the Dexter is probably to ask the user to disconnect it, look at the ports list, then reconnect it, and the port that shows up is the Dexter. Once the chip has enumerated as a serial port, the port number shouldn't change, even if the Dexter is disconnected and reconnected, so future communications should be immediate. 


#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-12-01 19:10](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-443450302):

I've liked this basic idea for a long time.

Why would we have stop kill and restart Dexrun?
Can't it just always listen on a serial port AND the regular socket
interface?
If it gets a valid oplet on the serial port, it handles it
as it would a regular oplet and sends out the response on the serial port.

As for detecting what serial port is a dexter, how about I do something
in DDE kind of like I did for Ping, i.e. send a "g" instruction to
all the serial ports and whichever ones return a value robot status,
I inform the user?

In a Dexter object instance in DDE, the ip_address can be a path
to a serial port instead of an IP address, and pretty
much DDE would work similarly.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-12-02 04:46](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-443481250):

It might be possible to accept commands from both the sockets and serial from the same run. But it would be a problem if both serial and network commands were sent at the same time. As long as we don't worry about that, it should be ok. We would need to flag the source of the command, so the response would go back to the same place... 

A mad scientist might connect a doomsday device to his or her USB port via the CP2102 and program it to blow up the world if it ever receives the command "g" for "go destroy the world". More seriously, you can't just send characters out serial ports without understand what the device on that port is going to do with that command. Perhaps we could setup the serial interface such that it would send a character or string /from/ dexter every so often... DDE could listen on each unconnected port for that signal. But in that case, if DexRun is always sending those string to the serial console will cause a serious slowdown when nothing is there to pick them up. Not sure how to resolve that issue.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-12-02 16:47](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-443521938):

"  More seriously, you can't just send characters out serial ports without
understand what the device on that port is going to do with that command."
My "port scanner" idea has this problem, but once you know that you're
using a particular serial port for something,
my architecture is the same as normal communications.
I agree that sending from Dexter every so often just in case DDE is
listening is bad.
We could automate the process somewhat of:
1. "grab list of serial port devices."
2. "tell user to plug in their Dexter"
3. "tell them what's changed in the list collected in step 1."

On Sat, Dec 1, 2018 at 11:46 PM JamesNewton <notifications@github.com>
wrote:

> It might be possible to accept commands from both the sockets and serial
> from the same run. But it would be a problem if both serial and network
> commands were sent at the same time. As long as we don't worry about that,
> it should be ok. We would need to flag the source of the command, so the
> response would go back to the same place...
>
> A mad scientist might connect a doomsday device to his or her USB port via
> the CP2102 and program it to blow up the world if it ever receives the
> command "g" for "go destroy the world". More seriously, you can't just send
> characters out serial ports without understand what the device on that port
> is going to do with that command. Perhaps we could setup the serial
> interface such that it would send a character or string /from/ dexter every
> so often... DDE could listen on each unconnected port for that signal. But
> in that case, if DexRun is always sending those string to the serial
> console will cause a serious slowdown when nothing is there to pick them
> up. Not sure how to resolve that issue.
>
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-443481250>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITfZGYUgm9qtEfb78WICu4T-nnxuBfks5u01sUgaJpZM4Y8vEe>
> .
>

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2018-12-03 06:23](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-443601603):

> The best way to id the Dexter is probably to ask the user to disconnect it, look at the ports list, then reconnect it, and the port that shows up is the Dexter.


> As for detecting what serial port is a dexter, how about I do something
in DDE kind of like I did for Ping, i.e. send a "g" instruction to
all the serial ports and whichever ones return a value robot status,
I inform the user?


> More seriously, you can't just send characters out serial ports without understand what the device on that port is going to do with that command.

This is what I do with lots of instruments, but they largely follow a standard protocol, SCPI.

Consider the industry standard (for test and measurement devices) [SCPI](https://en.wikipedia.org/wiki/Standard_Commands_for_Programmable_Instruments) query "*IDN?". Device should return a 4 field, comma delimited response identifying what it is, e.g.: "`TEKTRONIX,TDS 210,0,CF:91.1CT FV:v1.16 TDS2CM:CMV:v1.04`" means you're talking to a TEKTRONIX TDS210! The last field often says a serial number and firmware version.

Per [SCPI spec](http://www.ivifoundation.org/docs/scpi-99.pdf):
```
4.1.3.6 *IDN?
IEEE 488.2 is purposefully vague about the content of each of the four fields in the response syntax. SCPI adds no further requirement, but here are some suggestions:
All devices produced by a company should implement the *IDN? response consistently.
   Field 1, the Manufacturer field, should be identical for all devices produced by a single company.
   Field 2, the Model field, should NOT contain the word “MODEL”.
   Field 4, the Firmware level field, should contain information about all separately revisable subsystems. This information can be contained in single or multiple revision codes.
```

By sending an *IDN? string to each connected serial interface, I can know what is hooked up where. Sometimes devices use different commands, for those I send a sequence of termination characters so it clears its buffer and doesn't get confused next time something tries to talk to it (code at old company, don't recall what the sequence was, like \r\n maybe other obscure ASCII chars in a certain order). But, responding to *IDN? would allow you to play nice with others. I wouldn't be surprised if someone playing with Dexter also has a [programmable DC Powersupply, multimeter, oscilloscope, or somesuch](https://www.edn.com/electronics-blogs/test-cafe/4424791/SCPI-programming--Strengths-and-weaknesses) also connected over serial to his computer.

I don't think you need to deal with VISA to be nicer. It would say if something is already talking over that interface, so you don't interrupt!, and many other [nice features](https://www.taborelec.com/Tabor/UpLoadFiles/PGallery/20161201735195.gif), but maybe complexity of software not worth it (e.g. from DDE wrap around the VISA C API, requires installation of the _VISA Shared Components_). Handling "*IDN?" query would be sufficient.

**Dec04 EDIT:** If you do want to look into VISA, I suppose testing with any suitably licensed [3rd party's redistribution](https://www.rohde-schwarz.com/us/driver-pages/remote-control/3-visa-and-tools_231388.html) of the VISA Shared Components would be fine. Link against visa64.dll (or equivalent on Mac/Linux platforms). I apologize I can't do much coding right now... time crunch with other priorities but I thought I'd share this possibility with you. It is a nice technology, I highly recommend it especially if you want to connect to multiple devices (robot arms, other test & measurement devices) from the same computer and/or do the aforementioned serial polling by cfry. I don't believe there would be any [license](https://scdn.rohde-schwarz.com/ur/pws/dl_downloads/dl_application/application_notes/1dc02___rs_v/RS_VISA_Terms_and_Conditions.pdf) or vendor lock-in issues (you don't need NI products or MATLAB's instrument toolbox), you just need the visa64 shared library. Looks like the R&S VISA utilities are free anyway (but you don't need them, they're just nice & convenient UIs).

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-22 01:04](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-456236672):

The current placement of the fan, at the bottom of the microzed board, blocks all the USB connectors (and the sd card). Moving the fan out to the skin and ducting the air to the stepper motor drivers would give us the physical access we need for this USB connector... and the USB hub for connecting peripherals to Dexter.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-02 03:46](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-517536860):

The problem with a serial connection to the Zinq is that it is already connected to the CP2102 USB converter chip. To connect directly that chip would have to be removed or bypassed. 

An Android tablet (available for as little as $40) could host a USB OTG connection to the console connector on the microZed, and run an app developed to be the control panel, or an app that provides a terminal, or one that provides display services to a program running on Dexter.

It is possible to lock an Android down to a "kiosk" mode which runs only one app:
https://developer.android.com/work/dpc/dedicated-devices

An app like DroidScript (which runs JavaScript programs) can access the OTG USB port and communicate effectively. 
http://droidscript.org/

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-29 22:56](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-526391717):

The idea of using an Android tablet via USB OTG to the console cable appears to work well. An app has been developed that shows the basic functionality. 

The problem is finding a low cost but still in production tablet which will BOTH operate in OTG mode AND charge over a single USB port. A list has been started based on research:
http://techref.massmind.org/techref/io/usb/OTG.htm

In any case, this requires a special form of USB OTG cable: an Accessory Charging Adapter:
http://techref.massmind.org/techref/io/usb/power.htm#ACA

However, a tablet with a DC power jack avoids this issue by not using the USB connector for power. Currently an Ainol Q88 Android 7.1 with 1GB RAM is on the way. It has a DC power jack and is said to support OTG.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-09-07 04:02](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-529069872):

Ainol Q88 Android 7.1 works nicely and has been connected to the console overnight without discharging. It did NOT come with the DC power adapter, but I had one from the prior tablet which had died so I was able to use that. +5 volt 1 amp adapters are easily found. Getting the correct connector may be slightly more difficult, but can be done. Or the case can be opened / removed and the wires just soldered directly to the +5 volt bus on Dexter.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:47](https://github.com/HaddingtonDynamics/Dexter/issues/44#issuecomment-722055005):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/44)


-------------------------------------------------------------------------------

# [\#43 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/43) `closed`: Return directory / folder listing when read_from_robot request has 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-11-21 18:33](https://github.com/HaddingtonDynamics/Dexter/issues/43):

In order to support a better access to the file system on the robot via the socket interface, and avoid the need for a Samba or SFTP or other file transfer system, being able to read the directory listings from the robot is important.

We need to change the read_from_robot code in DexRun to look for a trailing / or \ in the request and if found, do an opendir / readdir instead of an fopen / fread. 
https://stackoverflow.com/questions/4204666/how-to-list-files-in-a-directory-in-a-c-program

Our current setup will need some adjustment to comply
https://github.com/HaddingtonDynamics/Dexter/blob/master/Firmware/DexRun.c#L2658

Since the blocks are sent in multiple socket buffers, one after the other, and returning a block that isn't full is the signal to DDE that the transfer is complete, we have to do several things:

1. Hold a flag that the current read is of a directory, not a file. We only get the requested data on the first request, so we don't have it when the second one comes in. Not too hard, we can just have a wdp variable as type DIR and check if wfp or wdp is non-zero for the subsequent blocks.

2. Return full blocks until all the files are listed. Rather than reading all the file names in to a RAM buffer on the first request, we can pad the returned file name out to the buffer size (MAX_CONTENT_CHARS) and return each file as each block is requested. e.g. block 1 is the first file name, padded to MAX_CONTENT_CHARS, then when block 2 is requested, we send the second file name in the folder, and so on.

3. When we have returned all the files / folder names in the directory, we need to signal the end. The C code won't really know that it's sent the last name (it returns null when you try to read the next name and it's at the end) so we will end up returning an empty block when DDE requests the next file after the last file was returned. That will stop DDE and adding a null block to the return string shouldn't cause a problem.
https://github.com/cfry/dde/blob/300634dbb73f4932e1f6352e83efb3894a913e5b/instruction.js#L3289

4. DDE will have this string with a bunch of spaces after each name so it will need to trim them for display / selection. 

We could skip this and implement #20 instead, then use a script to return the directory listing.


#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-11-21 21:57](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-440823400):

Its worth it to do some brainstorming here about
the things we might want to do in the future.

I like the idea of sending over a bash cmd
and getting a result especially if the bash cmd
operates with a consistent environment that
maintains its current working directory
so that the 2nd "cd" can take advantage of the first.

I'd also like to send over random JS, eval that on Dexter
and get back the result.

James N has his chat server stuff so how does that
all fit in?

Consider adopting the URL protocol syntax
(and maybe some of the semantics):
ie:  file://foo/bar.txt   gets file content
file://foo/   gets directory listing
js://(2 + 3)    returns 5
js://gripper_width()   returns a number in meters of the gripper width
With "js" protocol we just write a js method to implement
whatever is after the :// .  I'm inclined to use that heavily
and not invent another language.
We could have
js://bash("pwd")     for instance,
but admittedly
bash://pwd        has a certain appeal.

There is an existing "irc" protocol for chat, ie
irc://......
Seems to me read_from_robot's "source" arg
can be in the same "language" as used in the chat server.

The syntax of including arguments to a cmd in URLs
of foo?arg1=111&arg2=222
is Tim or his misguided minions inventing yet
another syntax for arg passing.
They should have just used JS syntax,
but they didn't even know enough to have the conversation.
(Maybe JS wasn't fully defined at the time, but
HTTP and HTMP are still language disasters.)

I recommend returned values be in JSON,
so our directory server could return an array of strings
for instance.

I like the idea of keeping the basic strategy we use
in read_from_robot  for collecting large values into one.
James N suggested sending over each file name in
a directory query as one item. But what if we have a
really long file name that can't fit in one?
Or a bunch of short files names that can fit
in many per packet?
I say, just consider the result to be some sort of
"virtual file" and send the whole thing over
as if it were a file.

On the dexrun side, seems to me the easiest thing to
do is make a "virtual file" of a result, then
treat it just as you treat files now.

On the DDE end, I have the original "query" at the
time of receiving the packets, including the last one,
so I can use that original query to format the result,
ie if its js://foo
I can assume the resultant virtual file is the source code
for a JSON object, and call the JSON parser on it
and return a nice structured  value.

Since its easier to format than to parse,
standardizing on sending JSON rather than just
sending random text and having its parsing be
idiosyncratic to the query will be less code.

To be continued ...




This message isn't meant to convey a spec,
just a conversation opener.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-11-21 23:54](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-440853751):

>
> Its worth it to do some brainstorming here about
> the things we might want to do in the future.
> I like the idea of sending over a bash cmd
> and getting a result especially if the bash cmd
> operates with a consistent environment that
> maintains its current working directory
> so that the 2nd "cd" can take advantage of the first.
>

It can also be sent a parameter of the folder we want the directory from.


> I'd also like to send over random JS, eval that on Dexter
> and get back the result.
>

Yeah, the bash command line can also fire up node.js, or send a message to
an existing node.js running in yet another thread.


> James N has his chat server stuff so how does that
> all fit in?
>

That's pretty much a separate
deal, which still talks through DexRun. Runs in another thread. Basically
you can think of it as an adapter cable. Pretty much all it does.


> Consider adopting the URL protocol syntax
> (and maybe some of the semantics):
> ie: file://foo/bar.txt gets file content
> file://foo/ gets directory listing
> js://(2 + 3) returns 5
> js://gripper_width() returns a number in meters of the gripper width
> With "js" protocol we just write a js method to implement
> whatever is after the :// . I'm inclined to use that heavily
> and not invent another language.
> We could have
> js://bash("pwd") for instance,
> but admittedly
> bash://pwd has a certain appeal.
> There is an existing "irc" protocol for chat, ie
> irc://......
> Seems to me read_from_robot's "source" arg
> can be in the same "language" as used in the chat server.
> The syntax of including arguments to a cmd in URLs
> of foo?arg1=111&arg2=222
> is Tim or his misguided minions inventing yet
> another syntax for arg passing.
> They should have just used JS syntax,
> but they didn't even know enough to have the conversation.
> (Maybe JS wasn't fully defined at the time, but
> HTTP and HTMP are still language disasters.)
>

For the read_from_robot, at least for now, we want to keep the request in
the old standard format because that's what our DexRun.c and the C compiler
will understand. I'd rather not have to write a converter... Although, I
guess it's just stripping off the "file:/" and keeping the "/dir/file"? I
guess that isn't so hard. Just look for it and strip it if it's there. Then
in the future, look for the "js:/" and "bash:/"... ok, not as bad an idea
as I thought it was in the first second. But it takes another bit of
work... have to remember to do it.


> I recommend returned values be in JSON,
> so our directory server could return an array of strings
> for instance.
>

Well, we can easily wrap each returned value in "[" and "]," and the
response to the first one can be "[" and the last one "]" but that leaves a
trailing comma on the last entry... Is that not valid JSON?

hang on, if we return the first file name in the first response, we can
pre-load a '[' in a temp variable, then return "[filename/ padding]" (no
comma) then pre-load temp with "," on every following request, except the
last one where we replace the "," with a "]" so you get something like
[[first                         ]
,[second                        ]
...
]
which I think is valid right? e.g. the commas don't have to be on the end.
In case it isn't clear, we don't send the trailing comma because we have no
way of knowing this is the last file until we get a null back from the OS
when asking for the next file name in the directory.


> I like the idea of keeping the basic strategy we use
> in read_from_robot for collecting large values into one.
> James N suggested sending over each file name in
> a directory query as one item.
> But what if we have a
> really long file name that can't fit in one?
>

Then we send it in two, or three, or whatever. Just like a file. The only
trick is we have to pad the last part of the file name so it doesn't stop
the transfer. so we might send
[[first                         ]
,[secondfilenamewhichisstupidlylo
ngandshouldneverbeusedbyanyidiotw
hoisnameingafile                ]
]


> Or a bunch of short files names that can fit
> in many per packet?
>

Yes, it is less efficient, but this is about what's easy to do in the
little C program on the little robot with limited memory. You big boys can
deal with it on the 64 bit computer with gigs of ram and a language that is
expected to garbage collect.


> I say, just consider the result to be some sort of
> "virtual file" and send the whole thing over
> as if it were a file.
> On the dexrun side, seems to me the easiest thing to
> do is make a "virtual file" of a result, then
> treat it just as you treat files now.
>

I thought about that, but when you have a very large directory, you have to
allocate and then free that much ram. Malloc and Free are good to avoid in
C programming. And in C++. And every other language when you are trying to
do real time programming. Garbage collecting the heap introduces all sort
of nasty timing issues. We really really don't want to do that if we can
help it.


> On the DDE end, I have the original "query" at the
> time of receiving the packets, including the last one,
> so I can use that original query to format the result,
> ie if its js://foo
> I can assume the resultant virtual file is the source code
> for a JSON object, and call the JSON parser on it
> and return a nice structured value.
> Since its easier to format than to parse,
> standardizing on sending JSON rather than just
> sending random text and having its parsing be
> idiosyncratic to the query will be less code.


Yep, I can see the advantage of that. And I think the JSON format is easy
enough to fake in C.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-11-22 00:17](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-440860141):

foo = [3, 4,]    is valid in new JS, ie the trailing comma is ok.
Cleaner is just don't use a comma on the first one,
and all the others, preceed with a comma.

Don't wrap each file name in square brackets, wrap them
in double quotes. We want a string.

On the malloc and ram requirements,
how about if there's just a special temp file
and you just write/pipe the JSON to that,
then when all done, send over the whole file
however you send over files now.
When you START the read_from_robot
just clear the content of the file.
Presuming we only have one such request at
a time, this shouldn't be tough.

If all the formatting work on the DexRun side is hard,
just pipe the output of "ls" to
a file, then send the file.
Same for every other bash cmd.
I can parse it on DDE's side, its not that hard.
Although generally its easier to format on
output than parse on input, we have a special
case here where harder to work in C on dex,
so that might be worth breaking my "rule" for :-) .

"ls" has a ton of options. we might want to use some of them,
ie file size & write date being the most generally useful.
Let's not do recursive decent, that's for the user of
DDE to choose.

More important than these details is the
larger "protocol" stuff, evaling bash and JS
and whenever else we decide on.
I'm expecting there to be a node running
on Dexter. Is that reasonable?
A special cmd might "boot' it.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-11 01:07](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-510286117):

1. Use 'r' command with block 0 and a directory name which must end in a '/' to indicate that it's a directory read vs a file read. On block 0, call opendir with the path specified by the oplet, and then call readdir to get a dirent structure with the next entries name, then call stat with the concatenated path and entry name to get the type, size, dates, etc... , then unpack that as JSON into a buffer string of sufficient size to avoid overrun. This size would be 61 + the maximum size of a JSON entry for a directory entry. e.g. the max entry name size, file size, dates, etc... Keep a pointer to the next free bytes in the buffer. Pre-load that buffer with an opening '{'. Return the first 62 bytes of the buffer in the expected 'r' format. If there is less than 62 bytes in the buffer, readdir another dirent and stat and unpack again. After copying that first 62 bytes into the reply, shift the buffer contents down 62 bytes so the next char to send is at the start of the buffer and point to the next free byte. The buffer, it's pointer, the dirent, and the dir handle must all be static across multiple calls.

2. Use 'r' oplet with non-zero block number (can increment, doesn't matter) to trigger reading of the next 62 bytes from the buffer. Anytime the buffer drops below 62 bytes readdir, stat, and unpack another entries data.

3. When readdir returns an error, we know that we've read all the data, so closedir and that becomes a flag to not readdir again (the dir handle being null). Append a closing '}' to the buffer, then just send back whatever data is left in the buffer. Until it is empty.

It should be obvious that doing a directory read in C is NOT a simple thing. Compare that to node.js which can do it in 22 lines of code with error checking.
https://code-maven.com/list-content-of-directory-with-nodejs

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-07-11 04:23](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-510323606):

Gad, 22 lines of code for a measly directory listing?
That JS library must have been written by a C programmer :-(
Have you actually implemented this yet?
I'd be interested to see an actual example
the returned dir listing.

Here's a wild idea if you haven't already implemented it:
Fire up node.js and just use that node code.
Write it to a file, then
"redirect" that read_from_robot("foo/bar/") to
read_from_robot("dir_listing_temp.json")


On Wed, Jul 10, 2019 at 9:07 PM JamesNewton <notifications@github.com>
wrote:

>
>    1.
>
>    Use 'r' command with block 0 and a directory name which must end in a
>    '/' to indicate that it's a directory read vs a file read. On block 0, call
>    opendir with the path specified by the oplet, and then call readdir to get
>    a dirent structure with the next entries name, then call stat with the
>    concatenated path and entry name to get the type, size, dates, etc... ,
>    then unpack that as JSON into a buffer string of sufficient size to avoid
>    overrun. This size would be 61 + the maximum size of a JSON entry for a
>    directory entry. e.g. the max entry name size, file size, dates, etc...
>    Keep a pointer to the next free bytes in the buffer. Pre-load that buffer
>    with an opening '{'. Return the first 62 bytes of the buffer in the
>    expected 'r' format. If there is less than 62 bytes in the buffer, readdir
>    another dirent and stat and unpack again. After copying that first 62 bytes
>    into the reply, shift the buffer contents down 62 bytes so the next char to
>    send is at the start of the buffer and point to the next free byte. The
>    buffer, it's pointer, the dirent, and the dir handle must all be static
>    across multiple calls.
>    2.
>
>    Use 'r' oplet with non-zero block number (can increment, doesn't
>    matter) to trigger reading of the next 62 bytes from the buffer. Anytime
>    the buffer drops below 62 bytes readdir, stat, and unpack another entries
>    data.
>    3.
>
>    When readdir returns an error, we know that we've read all the data,
>    so closedir and that becomes a flag to not readdir again (the dir handle
>    being null). Append a closing '}' to the buffer, then just send back
>    whatever data is left in the buffer. Until it is empty.
>
> It should be obvious that doing a directory read in C is NOT a simple
> thing. Compare that to node.js which can do it in 22 lines of code with
> error checking.
> https://code-maven.com/list-content-of-directory-with-nodejs
>
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/43?email_source=notifications&email_token=AAJBG7PGSE6VZUNAY7J5VK3P62BVTA5CNFSM4GFWXOSKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODZVFSJI#issuecomment-510286117>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/AAJBG7OA2AMWUD5UEMLP33DP62BVTANCNFSM4GFWXOSA>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-24 02:29](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-514454284):

Or we could just do this via #20

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-21 19:11](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-523608279):

Use #20

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:45](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-722054560):

Or better yet, do it via the node server web editor support. See wiki for node js server.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:45](https://github.com/HaddingtonDynamics/Dexter/issues/43#issuecomment-722054637):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/43)


-------------------------------------------------------------------------------

# [\#42 PR](https://github.com/HaddingtonDynamics/Dexter/pull/42) `closed`: Merge Dexter HD Firmware REQUIRES UPDATED GATEWARE .BIT FILE!

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-11-06 22:39](https://github.com/HaddingtonDynamics/Dexter/pull/42):

This update includes a new version of DexRun.c which depends on a matching version of the FPGA .BIT file. To use the new DexRun.c, install the new [Gateware](https://github.com/HaddingtonDynamics/Dexter/tree/master/Gateware) as per the Gateware readme

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-11-06 22:41](https://github.com/HaddingtonDynamics/Dexter/pull/42#issuecomment-436435855):

This update includes a new version of DexRun.c which depends on a matching version of the FPGA .BIT file. To use the new DexRun.c, install the new Gateware as per the Gateware readme.


-------------------------------------------------------------------------------

# [\#41 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/41) `closed`: Dexter.move_to_relative does not function in simulator mode.

#### <img src="https://avatars3.githubusercontent.com/u/39114649?v=4" width="50">[tasashlar](https://github.com/tasashlar) opened issue at [2018-10-13 06:02](https://github.com/HaddingtonDynamics/Dexter/issues/41):

DDE 2.4.3 osx 10.12.6

Team,

I was doing some pre-emptive dev work before receiving my dexter and the function:

dexter.move_to _relative does not appear to work on the sim.

When executing the following code based on the doc

new Job({name: "test_job",
         do_list: [Dexter.move_all_joints(Dexter.NEUTRAL_ANGLES),
                   Dexter.move_to_relative([0.005, 0.01, 0]),
                   Dexter.move_to([0.1, 0.1, 0.1])
                   ]})
The sim does not reflective any movement at all. All lines after the move_to_relative in the job also fail.
If you comment out the move_to_relative it all appears to work as expected.

Is this because the function needs position data from the robot and the sim does not emulate it it fully?
Other Ideas?

Thanks


#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-10-15 04:02](https://github.com/HaddingtonDynamics/Dexter/issues/41#issuecomment-429701958):

Thanks for the bug report.
I am running a very new release of DDE and I have been tweaking the
move commands so its *possible* that I fixed a bug I didn't know we had!
But another possibility is that you commanded Dexter to move out of range.
You didn't give say if there were any error messages, but
its normal that when moving to some random x, y z location, it will
be out of range. This will cause the job to error.
The Job's button will turn red and there will be a tooltip on the button with
an error message. For out of range problems you should also see
some red test error message in output pane.
When I run your code on my latest DDE version the job runs to completion without
erroring, but it doesn't *look* like it makes all the moves it should.
new Job({name: "test_job",
	do_list: [Dexter.move_all_joints([0, 30, 30, 30, 30]),
				Dexter.move_to_relative([0.05, 0.01, 0.01]),
			  Dexter.move_to([0.1, 0.1, 0.1])
]})
is a job that makes the relative move more obvious,
but you still have to look carefully at the simulation.

Playing with DDE simulator before getting your dexter is indeed a good thing 
to do before getting your Dexter. 
I encourage you to click on the big blue ? in the upper right
of the doc pane to see how to get help within DDE.

Once we have a few days experience with my new release,
and it checks out ok, I'll make it public.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:41](https://github.com/HaddingtonDynamics/Dexter/issues/41#issuecomment-722053389):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/41)


-------------------------------------------------------------------------------

# [\#40 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/40) `closed`: Can't connect to Dexter, no "boot dance", blue/green/red LEDs on solid.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-10-12 22:11](https://github.com/HaddingtonDynamics/Dexter/issues/40):

Sometimes on powering Dexter up, the RED LED (right side, facing the [MicroZed](https://github.com/HaddingtonDynamics/Dexter/wiki/MicroZed) control board) will stay steady, and not blink. The RJ-45 connector housing LED's may blink if there is a CAT5 cable plugged in. The robot will not boot-dance, and no method of connecting to the robot works, even if it did before.

**This is typically caused by a bad or missing or not fully inserted sd card.**

It is very easy to not have the sdcard fully or correctly inserted. Especially after connecting to Dexter via the [USB Micro A connector](https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-USB-Connection) because the edge of the USB cable can easily press the sd card up and unseat it. 

One can also have a card that is not all the way up into the slot; the card has to be pressed up until a slight click is heard, and then it can not be pulled back out. If a downward tug on the card removes it, then it wasn't in correctly.

If the card is inserted securely, it may be that the data on it is corrupt or it may be empty. See:
https://github.com/HaddingtonDynamics/Dexter/wiki/SD-Card-Image
for how to burn a good image onto an SD card.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:40](https://github.com/HaddingtonDynamics/Dexter/issues/40#issuecomment-722053146):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/40)


-------------------------------------------------------------------------------

# [\#39 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/39) `open`: Encoder disks difficult to print on some 3D printers

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-10-02 22:48](https://github.com/HaddingtonDynamics/Dexter/issues/39):

Because the spacing / gap of the slots on the encoder disks was specifically optimized for certain 3D printers, they can be difficult to print well even on higher resolution printers. If the resolution of the printer / size of the extruded filament doesn't exactly match the design, the slicing can mess up by attempting to get more than one filament pass between some slots and only one between others. 

It may be better to design a disk for laser cutting. 

Or it may be that very high resolution (e.g. resin) printers are a good choice.

#### <img src="https://avatars2.githubusercontent.com/u/43831892?v=4" width="50">[CaliTarheel](https://github.com/CaliTarheel) commented at [2018-10-03 22:50](https://github.com/HaddingtonDynamics/Dexter/issues/39#issuecomment-426829430):

I can experiment with both.

#### <img src="https://avatars2.githubusercontent.com/u/43831892?v=4" width="50">[CaliTarheel](https://github.com/CaliTarheel) commented at [2018-10-03 23:01](https://github.com/HaddingtonDynamics/Dexter/issues/39#issuecomment-426831602):

If I can have a DXF file of what the laser cut needs to be, I can experiment with that on some 2.9mm black acrylic. 
[Disk.zip](https://github.com/HaddingtonDynamics/Dexter/files/2444312/Disk.zip)

I have a form 2 and am game to try printing out the attached file.  The file can be read with Preform, downloadable from https://formlabs.com/tools/preform/ so you can see how the supports attach.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-04 16:28](https://github.com/HaddingtonDynamics/Dexter/issues/39#issuecomment-427083746):

Thanks @CaliTarheel we appreciate it. 

We don't have expertise available on resin printing, so our opinions on where supports should be wouldn't really matter. Probably the best thing to do is just try the print and send it to us for testing. 

I will look into how to convert the files into DXF format for laser cutting. Getting the correct thickness of material may be an issue. The disks need to be about 0.04" / 1mm thick to pass through the optical slot, while still being completely opaque.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-04 16:30](https://github.com/HaddingtonDynamics/Dexter/issues/39#issuecomment-427084479):

Just to clarify again, the DIFF disks are less interesting because they are smaller and have a lower slot count and mounting them is difficult. The disks that are worth trying are the pivot, base, and end arm disks.

#### <img src="https://avatars2.githubusercontent.com/u/43831892?v=4" width="50">[CaliTarheel](https://github.com/CaliTarheel) commented at [2018-10-04 16:40](https://github.com/HaddingtonDynamics/Dexter/issues/39#issuecomment-427087819):

James, 

For the supports, the idea is to keep them close to but not touching critical tolerances.  Some sanding or pocking can occur. which is why I've tried to keep them away from the slots and the inner side of the ring.

I'll take out the DIFF disk and see how the other one goes.

If the STL files are accurate, which they'd need to be, I can reverse engineer from those.  Though it looks like it'll be about 6 weeks before I can get the 1mm acrylic needed to test it.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-04 16:46](https://github.com/HaddingtonDynamics/Dexter/issues/39#issuecomment-427089836):

@CaliTarheel great, thanks!

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:38](https://github.com/HaddingtonDynamics/Dexter/issues/39#issuecomment-722052588):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/39)


-------------------------------------------------------------------------------

# [\#38 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/38) `open`: Get Software Certification

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-09-17 23:56](https://github.com/HaddingtonDynamics/Dexter/issues/38):

Work with [KitWare](https://www.kitware.com/) to provide software medical certification.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:37](https://github.com/HaddingtonDynamics/Dexter/issues/38#issuecomment-722052181):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/38)


-------------------------------------------------------------------------------

# [\#37 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/37) `closed`: Can't directly CAT5 between PC and Dexter since DHCP enabled
**Labels**: `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-09-14 23:44](https://github.com/HaddingtonDynamics/Dexter/issues/37):

When Dexters had a fixed ip address, you could just connect a CAT5 cable between the PC and Dexter and it would work. And yes, that is perfectly valid electrically... Ethernet signaling is specifically setup to work in that configuration, so that when only two devices need to be interconnected, no hub or router or anything else is really needed. 

Now, there were problems if you enabled your WiFi and it went up on a different subnet, but that was fixable by changing Dexters IP. E.g. if your WiFi local addresses were 192.168.0 and Dexter was set to 192.168.1.142 then it would not work. But you could disconnect from WiFi, set your PC to a fixed 192.168.1.141 address, SSH into Dexter and change it's IP address to 192.168.0.142, then release your PC's static IP and sign back into WiFi. Your PC to the internet via WiFi, Dexter to your PC via CAT5.

When Dexter's firmware was changed to use DHCP, it was MUCH better for use on a real network, but that requires that we have a router with DHCP for Dexter and the PC to connect into. Carrying the extra router is a pain when doing demos, and it is often the case that users don't have CAT5 connections available to their local routers, relying instead of WiFi for all connections; which Dexter can't support at this time, and isn't really desirable anyway for a security on a robot.

It would be nice to have Dexter start in DHCP, and then if that isn't found, fall back to a static IP.



#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-14 23:47](https://github.com/HaddingtonDynamics/Dexter/issues/37#issuecomment-421511947):

A partial (hack) solution is to set a fixed IP which is always up, in addition to the DHCP address. After SSHing into  Dexter:

`nano /etc/dhcp/dhclient.conf`

and comment IN the alias section, then edit it to pick a static address that won't cause issues on your network. e.g. the fixed ip for the robot. I used one on my 192.168.0 network, but you should be able to use any local network address that isn't the same as your PC or anything else on your network (because it will also be active when connected to your local router). If you pick an address that is in the DHCP range, or otherwise could be assigned to another device on the network, you won't be able to talk to either device reliably. This is the major limitation of this solution.

alias {
  interface "eth0";
  fixed-address 192.168.0.138;
  option subnet-mask 255.255.255.255;
}

I also set a faster timeout and retry, but that shouldn't be necessary.

timeout 5;
retry 60;

And now, that will NOT work... because there is a service that messes it up:
https://linux.die.net/man/8/avahi-autoipd
by overriding DHCP when it fails and assigning it's own "adhoc" ip address in the 169.254.1. net. Mine always came up on .141 but I don't know if that is consistent (couldn't find a way to control it) then you have to reconfigure your PC and even then I couldn't get it to actually communicate on that address. 

So you want to disable the avahi daemon for this to work... but you can't. I tried everything to "neatly" turn it off and it would come back on no matter what. So... I went a bit nuclear on it:

`apt-get remove avahi-daemon `

now, that also removes: 
````
Removing avahi-utils ...
Removing telepathy-salut ...
Removing libnss-mdns ...
````

I don't think we will be doing anything with telephony services (which is what telepathy-salut provides) and the libnss-mdns service is the one that lets you find the device on the .local network. *shrug* I've never used that. 

Now when you start the bot, it takes a minute or two, and then then fixed address will come up and start working. Yeah!

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-28 05:38](https://github.com/HaddingtonDynamics/Dexter/issues/37#issuecomment-425326600):

To gain access to Dexters command line in order to make these or other changes to the Network configuration, a USB connection can be made:
https://github.com/HaddingtonDynamics/Dexter/wiki/Dexter-USB-Connection

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-08 22:08](https://github.com/HaddingtonDynamics/Dexter/issues/37#issuecomment-427994971):

In the end, it's probably better to set the default / starting sd card image up with a simple fixed IP address. If users who are on a large network need to reach multiple Dexters, their networking people can reconfigure them to use DHCP and answer any network security issues at the same time. The fix ip has the following advantages:
- Works out of the box by directly connecting to a local computer via CAT 5 and a known IP. No need to figure out the COM number, install drivers, find the IP address, etc... 
- Avoids issues of network vulnerability by working only with the locally connected PC. 
- Works even when the local network is WiFi only (no CAT 5 connections to the local router).

TODO: Create new image with Fixed IP address.

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2018-12-03 06:54](https://github.com/HaddingtonDynamics/Dexter/issues/37#issuecomment-443607186):

Perhaps [UPnP](https://en.wikipedia.org/wiki/Universal_Plug_and_Play) would interest you? Search for a javascript UPnP library. UPnP can also forward ports on routers which support it (how video games automatically set up connections directly between peers without the user having to configure their router), but it's more of a residential technology. Might help with #31 anyway (for residential networks through NAT traversal, but UPnP NAT feature on routers probably disabled on secure/commercial network).

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-01 20:07](https://github.com/HaddingtonDynamics/Dexter/issues/37#issuecomment-459851513):

This is effectively resolved with the new OS image as per #25

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-05 00:35](https://github.com/HaddingtonDynamics/Dexter/issues/37#issuecomment-722051732):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/37)


-------------------------------------------------------------------------------

# [\#36 PR](https://github.com/HaddingtonDynamics/Dexter/pull/36) `closed`: Add Joint 6, 7 support for move all joints

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-09-12 23:23](https://github.com/HaddingtonDynamics/Dexter/pull/36):

Accept 2 additional values on the "a" (move all joints) instruction and send those out to set gripper roll and span. This integrates the 2 new servo joints into the move all joints system, bringing it from 5 joints to 7 joints.

However, DDE may not correctly send these values as of 2.5.3. This may happen even when only 5 values are sent in the DDE `Dexter.move_all_joints` command as it will try to guess where Joints 6 and 7 were before. There are two problems:

1. DDE is incorrectly converting the Joint 6 and 7 values. It seems to always send 3600 for joint 6 and 7200 for joint 7. There is some question as to what the values sent should be. Either:

- The value should be in arcseconds and the firmware should be updated to convert that to degrees for the Dynamixel servo, or

- The value should be sent in degrees and the Firmware should just pass it through. (current)

2. The initial values for these joints may not be set correctly.

Also, because the SetParam EERoll and EESpan commands also set the End Effector positions (which are Joints 6 and 7), DDE may not correctly track the commanded position, and if a 5 axes Dexter.move_all_joints command is issued, it will assume the user wants Joint 6 and 7 at their last known position, which may be different from where they are now due to the EERoll and EESpan SetParm commands. Either:

1. DDE could just NOT send positions when it isn't given position for higher order joints. This seems safest.

2. DDE could monitor the EERoll and EESpan commands to stay in the loop on their commanded positions. 

See:

https://github.com/cfry/dde/issues/35

https://github.com/HaddingtonDynamics/Dexter/wiki/set-parameter-oplet




-------------------------------------------------------------------------------

# [\#35 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/35) `closed`: Startup / Home Dexter in Positions other than Straight up

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-09-04 22:15](https://github.com/HaddingtonDynamics/Dexter/issues/35):

In some applications, it is not possible to have Dexter setup in a completely straight or vertical position. It would be good to be able to start Dexter in an offset position.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-09-04 23:09](https://github.com/HaddingtonDynamics/Dexter/issues/35#issuecomment-418546459):

I am expecting most jobs to assume Dexter could be
in any position at startup and thus they
should move dexter to a "starting position" before
doing the domain-specific activity of the job.
Do to tool paths and things that "might be in the way",
this might mean moving dexter twice,
ie once "straight up" as far as it can go"
then, now that its theoretically clear of the workspace,
over to a high "x, y start position".
Then from THERE we start the job's specific movements
in earnest.

One trick to normally avoid obstacles is
before moving TO somewhere on the work surface,
first move up to a neutral high position.
This won't always work, but is a good heuristic.

On Tue, Sep 4, 2018 at 6:15 PM JamesNewton <notifications@github.com> wrote:

> In some applications, it is not possible to have Dexter setup in a
> completely straight or vertical position. It would be good to be able to
> start Dexter in an offset position.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/35>, or mute the
> thread
> <https://github.com/notifications/unsubscribe-auth/ABITfZSj1lphBB74pN-6DwIZjsNITPhXks5uXvt9gaJpZM4WZ3TC>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-08 22:11](https://github.com/HaddingtonDynamics/Dexter/issues/35#issuecomment-427995573):

b5c8c9815294405c8ec51c3ce6bdb3ed3433e139 is an effective workaround for this but it will not help if you are using DDE to do kinematics. (e.g. Dexter.move_to )

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 23:51](https://github.com/HaddingtonDynamics/Dexter/issues/35#issuecomment-722036644):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/35)


-------------------------------------------------------------------------------

# [\#34 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/34) `closed`: Update BOM spreadsheet
**Labels**: `Hardware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-08-21 18:23](https://github.com/HaddingtonDynamics/Dexter/issues/34):

https://docs.google.com/spreadsheets/d/1uk89q76vcK4OT9NTM6qxsPpkON_QM3-OrlhfjPigGuE

Bring up todate with kickstarter and HD tabs

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-08-22 18:30](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-415133093):

I like this list of parts.
It helps me get a feel for just how complex a Dexter is.

If the comment:
"Bring up todate with kickstarter and HD tabs"
is a "do list item" for this spreadsheet,
I'd add to that
1. What is this a parts list for?
 The only title is
"NOTE: THIS SHEET NEEDS TO BE UPDATED AND MAY BE INCORRECT"

2. Date.

3. state explicitly that the "sidebar" of "Total Hardware " is redundant
with those same parts mentioned elsewhere (if that's the case).
I like having the "total hardware" but it doesn't add to the
total parts count if I understand it correctly.

4. make a total parts count for every one of the "sub-sub assemblies"
5. Make a total parts count for each subassembly.
6. Make a grand total parts count.
this will help us compare the complexity of different Dexter versions.
As I understand it, the HD Dexter has many fewer parts so
it would be nice to have a comparison of the progress that's
been made with the HD design.


On Tue, Aug 21, 2018 at 2:23 PM, JamesNewton <notifications@github.com>
wrote:

> https://docs.google.com/spreadsheets/d/1uk89q76vcK4OT9NTM6qxsPpkON_
> QM3-OrlhfjPigGuE
>
> Bring up todate with kickstarter and HD tabs
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/34>, or mute the
> thread
> <https://github.com/notifications/unsubscribe-auth/ABITfaGVOpgawJPogsg6c0VCMglzfA6lks5uTFAZgaJpZM4WGWAH>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/1403707?v=4" width="50">[Brandon Vandegrift](https://github.com/bmv437) commented at [2018-11-04 15:15](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-435677928):

Have you considered using a PBS (Product Breakdown Structure) for the parts and assemblies?
Another very complex project I follow just posted a video about how a PBS changed the way they tackle the project:

https://www.youtube.com/watch?v=zVyEsMiwvVc

Here's their Blank PBS Template with analytics:
https://docs.google.com/spreadsheets/d/1eKW_-ygHTu2z4inSSGPFnjAoIolORW19d-Xu-uhDw9E/edit

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-11-04 17:58](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-435691323):

I certainly have! If I could find the time I would do it. If you have time, please help us? P.S. I LOVE marble machine x!

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2018-11-21 02:44](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-440508440):

PBS looks useful. I made an [attempt](https://docs.google.com/spreadsheets/d/1hJnaWNOxw2grD4kduyf22FARP7wVjzjn6f_6CNK4B-Y/edit?usp=sharing).

By macro (javascript) it makes a list of 3D parts, hardware, and their quantity from the main tab. Sorted alphabetically. Run the **populate_tabs** macro to update the tabs. Another macro is in there to autogenerate the PBS #s.

The assemblies/parts match OnShape's instances list. Row groups, dashes, and spaces in the names help show hierarchy.

EDIT: OnShape has no free API to pull the hierarchy from AFAIK. Can automate this document creation/update by exporting OnShape into some other CAD suite, then translating that into the spreadsheet.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-11-21 17:47](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-440754390):

Wow @AndrewSmart that rocks! Thank you! 

I hope you can help me understand it better?
1. it looks like the harmonic drives aren't included in the hardware tab. Apparently, that's because they aren't assigned a type. Looking at line 110 / 110 in the list shows the type set to nothing. Is correcting that just as easy as changing the type to H for hardware?

2. The "bottom section" and "second section" don't appear to have any detail in them. But those sections do have detail in them in OnShape. Was that part of the setup just not finished? I'd like to learn how to finish it if you have time for a call or other means of educating me. 

3. Is there a way of getting the default quantity to be 1 or some other way to total the e.g. number of ball bearings one needs? Looking at the Hardware tab there are a number of KP0056-01_SB6703ZZ_2_03 ball bearings, but no idea how many total you need to order. Is there a way of getting that information? I thought the Wintergatan PBS did that?

Again, thank you for this amazing effort, and I really hope we can work together to bring it to full use.

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2018-11-21 19:01](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-440776111):

> 1. it looks like the harmonic drives aren't included in the hardware tab. Apparently, that's because they aren't assigned a type. Looking at line 110 / 110 in the list shows the type set to nothing. Is correcting that just as easy as changing the type to H for hardware?

Yes H for hardware, then re-run the **populate_tabs** macro to update.
It seemed like the harmonic drives had multiple sub-parts, in this model are they the cycloidal drives? I couldn't tell at a glance. Multiple things in there I probably classified wrong (like the shafts, Idk which are steel, CF, or printed without searching the webinars for each one).

> 2. The "bottom section" and "second section" don't appear to have any detail in them. But those sections do have detail in them in OnShape. Was that part of the setup just not finished? I'd like to learn how to finish it if you have time for a call or other means of educating me.

Correct I hadn't finished it by hand. Just showing what I had as a demonstration. I'd like to look into a more automatic way of making it.

> 3. Is there a way of getting the default quantity to be 1 or some other way to total the e.g. number of ball bearings one needs? Looking at the Hardware tab there are a number of KP0056-01_SB6703ZZ_2_03 ball bearings, but no idea how many total you need to order. Is there a way of getting that information?

Via macro a sum of multiple instances could be tallied. A grouping structure on that page seems most appropriate to see where the instances are. I hadn't written that yet. e.g.:
```
   PBS #             NAME                 QUANTITY
+--total----  KP0056-01_SB6703ZZ_2_03     8
|--1000-01    KP0056-01_SB6703ZZ_2_03     2
|--2530-12    KP0056-01_SB6703ZZ_2_03     4
|--3120-03    KP0056-01_SB6703ZZ_2_03     2
....
```

> I thought the Wintergatan PBS did that?

~~Not the publicly released document linked above by bmv437. It didn't have the analytics mentioned in the video; I'm guessing they kept their analytics private~~ (**EDIT:** link to analytics in youtube video). The additional tabs/macros were made by me. The macros are written in javascript [[1]](https://developers.google.com/apps-script/reference/spreadsheet/sheet)[[2]](https://developers.google.com/apps-script/reference/spreadsheet/range), easy stuff.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-11-21 19:25](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-440782620):

In the OnShape version (which was exported from some other CAD package... SolidWorks? I'm not the mechanical engineer) the Dexter is a version 1 (aka "Kickstarter" version) which certainly uses harmonic drives, not cycloidal. The new Dexter HD /may/ use cycloidal, but they are still in development. 

@JamesWigglesworth probably knows a lot more about what CAD is going to be used going forward. James, we should ask Avery / Noah what features the PBS could have that would most help him with assembly / parts ordering. With that info, we can better design a macro to populate the tabs. And if we use it, then it will be kept up to date for others. 

@AndrewSmart if we know the CAD system, then can you help us export the data in a way that can be imported into the PBS?

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2018-11-22 05:25](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-440916772):

> > 1. Is there a way of getting the default quantity to be 1 or some other way to total the e.g. number of ball bearings one needs? Looking at the Hardware tab there are a number of KP0056-01_SB6703ZZ_2_03 ball bearings, but no idea how many total you need to order. Is there a way of getting that information?
> 
> Via macro a sum of multiple instances could be tallied. A grouping structure on that page seems most appropriate to see where the instances are. I hadn't written that yet. e.g.:
> 
> ```
>    PBS #             NAME                 QUANTITY
> +--total----  KP0056-01_SB6703ZZ_2_03     8
> |--1000-01    KP0056-01_SB6703ZZ_2_03     2
> |--2530-12    KP0056-01_SB6703ZZ_2_03     4
> |--3120-03    KP0056-01_SB6703ZZ_2_03     2
> ....
> ```

Ok, I implemented this grouping. You can easily see total hardware/print counts now.

I also fixed a bug with quantities not being calculated correctly when an assembly had multiple instances. Also PBS #'s now link to the PBS tab. I left a blank quantity to mean "1", I felt having 1's everywhere cluttered things up on the PBS tab, but I suppose they're fine on the other tabs.

> if we know the CAD system, then can you help us export the data in a way that can be imported into the PBS?

If it's SolidWorks or some other proprietary system I probably can't, I don't have a copy. In the past I found a DLL in a free SolidEdge viewer, I used that to parse the SolidEdge files and display the geometry, but that was tricky and I don't have that code anymore. I don't want to deal with sparsely documented DLLs again.

If it's FreeCAD I could do it. I was just going to import the OnShape model into FreeCAD, then use Python in FreeCAD to traverse/output the hierarchy to a csv... import that into a new spreadsheet tab, run macro on it to update the spreadsheet. Probably the simplest approach.

This spreadsheet so far was just low hanging fruit for me! Hope it helps.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-11-22 05:32](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-440917792):

Thanks Andrew! I'm understanding that we used Inventor initially, and are now switching to Fusion 360. More when @JamesWigglesworth is available, probably next week.

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2018-11-30 06:29](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-443105302):

> > I thought the Wintergatan PBS did that?
> 
> Not the publicly released document linked above by bmv437. It didn't have the analytics mentioned in the video; I'm guessing they kept their analytics private.

Nevermind, looks like their [analytics document](https://docs.google.com/spreadsheets/d/1PO7k6SIv7zeu3BrW5R6h3_LwHFuZYSnFIQQtwokskCg/edit#gid=798417849) is separately linked to under their youtube video.

> > if we know the CAD system, then can you help us export the data in a way that can be imported into the PBS?
>
> I was just going to import the OnShape model into FreeCAD, then use Python in FreeCAD to traverse/output the hierarchy to a csv... import that into a new spreadsheet tab, run macro on it to update the spreadsheet. Probably the simplest approach.

Ok, I've:
1. Exported the STEP file from OnShape (or from any CAD Suite the model may be in). Caution: hidden parts were not exported, make sure to unhide all prior to export.
1. Imported the STEP file into FreeCAD
1. Ran a FreeCAD python macro I wrote to make the csv, and
1. Imported that csv into a new tab in the PBS spreadsheet.
1. Merged that into the PBS tab by hand (made a new column and compared hierarchy by eye).

I've not written the macro to update the PBS tab using said CSV tab, I thought (5.) in the procedure above is good enough. Code is [all here](https://github.com/AndrewSmart/ProductBreakdownStructure).

As a suggestion so that parts can be classified automatically is to assign each type (hardware/carbon/plastic) a color in the CAD model (even a RGB channel off-by-1 is fine). That color is exported into the STEP file, and can then be utilized to classify the part via script. Everything could instead be classified by hand in the PBS tab (as it is now) so no big deal either way.

This BOM doesn't include stuff like the finishing nails as they are not in the CAD model, I expect you could add parts like that to the PBS tab by hand if you want to go that route, or add them to the CAD model.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-11-30 07:12](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-443113127):

Thanks Andrew! Couple of questions:
1. I can't expand the collapsed sections on the PBS tab. It says I'm trying to edit a protected cell or object. But I can change the status and other columns... 
2. On the hardware tab, some items are totaled and others are not, I'm trying to understand what triggers that or misses that. e.g. lines 25-27 should probably be totaled. I'm looking for the code that makes that choice but I don't see it. Did you just do that manually?

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2018-11-30 09:19](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-443141678):

> 1. I can't expand the collapsed sections on the PBS tab. It says I'm trying to edit a protected cell or object. But I can change the status and other columns...

Ok strange, everyone with the link can edit the entire document. I did protect column A from edits as that is autogenerated. I guess that prevented others from expanding the row groups, so I've removed that protection, must be a bug with Google Sheets.
Should work now.

> 2. On the hardware tab, some items are totaled and others are not, I'm trying to understand what triggers that or misses that. e.g. lines 25-27 should probably be totaled. I'm looking for the code that makes that choice but I don't see it. Did you just do that manually?

Nope did not do it manually, grouping is done automatically on the BOM tabs. The code that does it is `function group_sheet`.

I'll try to fix that real quick. **EDIT:** Ok works now.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-12-02 05:19](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-443482609):

Andrew, that's excellent! It really looks quite nice now. 

Our lead mechanical engineer, @JamesWigglesworth, tells me that we are standardizing on Fusion 360 for new designs. Have you worked with that before? There are free (as in free to use, not open source) licenses for it that individuals can get for non-commercial work if you would like to try it. I assume the current process would be the same? Export the STEP files from Fusion, import into FreeCAD, run the macro, move the data into the sheet?

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2018-12-02 08:33](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-443490850):

Thank you. Nope, I have not worked with Fusion 360.
> I assume the current process would be the same? Export the STEP files from Fusion, import into FreeCAD, run the macro, move the data into the sheet?

Correct. Reminds me, I ought to share this document/workflow with the [FreeCAD community](https://forum.freecadweb.org/viewtopic.php?f=8&t=23592&start=30#p271798).

#### <img src="https://avatars3.githubusercontent.com/u/25123?v=4" width="50">[Max Suica](https://github.com/maxsu) commented at [2019-08-21 09:15](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-523371912):

@JamesNewton, @AndrewSmart: 

1. What's the status on the PBS-BoM update?
2. What's the status on the Onshape to F360 migration? 
3. What's our current best thinking on unobtrusive PBS-style part/assembly numbering in F360?

@AndrewSmart, since F360 is freely available to potential collaborators and extensible /w python, I'd like to recommend we skip Freecad as a project dependency and work in F360. We can find or [develop](https://help.autodesk.com/view/fusion360/ENU/?guid=GUID-9701BBA7-EC0E-4016-A9C8-964AA4838954) an [add-in](https://knowledge.autodesk.com/search-result/caas/sfdcarticles/sfdcarticles/How-to-install-an-ADD-IN-and-Script-in-Fusion-360.html) to update the BOM after substantive changes. Currently looking at your [Freecad Macro](https://github.com/AndrewSmart/ProductBreakdownStructure/blob/master/export_to_pbs_csv.FCMacro) - at first glance it will not be hard to port over (with the proviso that F360 has a similar assembly hierarchy.)

If we build the add-in from scratch, I'd like to reuse it in other F360-standardized open hardware projects (I'd like to use a similar PBS methodology for [StanfordDoggo](https://github.com/Nate711/StanfordDoggoProject)) - I think the existing macro's philosophy meets that requirement.

@AndrewSmart  can you share a quick example of the CSV output from your FCMacro? I'd like to document the existing PBS.csv format.

Tentative next steps here: 
1. Find or dev PBS.csv-compatible BoM add-in for F360
2. Locate Dexter F360 model; Add @AndrewSmart's PBS numbering
3. Integrate BoM add-in; draft updated BoM contributor workflow
4. Update and push the new PBS-BoM

#### <img src="https://avatars2.githubusercontent.com/u/5455129?v=4" width="50">[AndrewRichardSmart](https://github.com/AndrewSmart) commented at [2019-08-21 17:33](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-523567504):

> @AndrewSmart can you share a quick example of the CSV output from your FCMacro? I'd like to document the existing PBS.csv format.

@maxsu It's in the last tab of the [google sheet](https://docs.google.com/spreadsheets/d/1hJnaWNOxw2grD4kduyf22FARP7wVjzjn6f_6CNK4B-Y/edit?usp=sharing) I made. I just imported the CSV into that 'ImportCSV' tab, then... I think I manually copied over the columns to the PBS tab, I don't believe that workflow was scripted.

More scripting would need to be done to automate updates, e.g. propagating parts added/removed from CAD model to the PBS document, handling conflicts or whatever (e.g. strikethrough of deprecated parts). Also I don't think grouping on the PBS tab was scripted, I did that manually. I didn't think scripting those features worth the effort if HD wasn't going to use it, but what I did met my needs so I didn't do more. But it does sound like they may use this workflow if it uses F360.

Yes I changed the PBS numbering a bit to handle the hierarchy depth.

**EDIT:** Also let me know if you want the code as CC BY-SA or whatever instead of GPL2.

#### <img src="https://avatars3.githubusercontent.com/u/5458696?v=4" width="50">[jonfurniss](https://github.com/jonfurniss) commented at [2019-08-21 19:17](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-523610591):

@maxsu We are currently on the tail end of finishing up the Fusion 360 port and assembly. To be able to more easily edit parts in the future, we redrew everything from scratch in Fusion. We are internally going through to test everything out and make sure it's correct, so we're not quite ready to share it publicly yet. 
We started using the PBS numbering system for our part numbers, which we have put as a prefix on each part as we redrew them, which I assume will make the scripting process work easier.
We definitely welcome any help for automatically extracting a PBS BOM from Fusion 360 with an add-in or Python script.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 23:49](https://github.com/HaddingtonDynamics/Dexter/issues/34#issuecomment-722036277):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/34)


-------------------------------------------------------------------------------

# [\#33 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/33) `closed`: Change mode with SetMode oplet

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-08-07 22:16](https://github.com/HaddingtonDynamics/Dexter/issues/33):

To make it very very easy to change modes (keep, follow, protect) add a new [SetMode](https://github.com/HaddingtonDynamics/Dexter/wiki/set-parameter-oplet) sub-item to set all the FPGA parameters in one shot. 

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-08-09 15:35](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-411800536):

See DDE Ref Man/Robot/Dexter/Dexter Instructions/
set_follow_me,
set_force_protect
set_keep_position
set_open_loop


On Tue, Aug 7, 2018 at 6:16 PM, JamesNewton <notifications@github.com>
wrote:

> To make it very very easy to change modes (keep, follow, protect) add a
> new SetMode
> <https://github.com/HaddingtonDynamics/Dexter/wiki/set-parameter-oplet>
> sub-item to set all the FPGA parameters in one shot.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/33>, or mute the
> thread
> <https://github.com/notifications/unsubscribe-auth/ABITfaFicop-ws1GqOgbvi1GZyoUzuyPks5uOhHBgaJpZM4Vy-ay>
> .
>

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) commented at [2018-08-09 19:45](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-411874559):

This is talking about those exact functions but in the form of single oplet instructions to make it easy on the non-dde user.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-08-23 00:09](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-415228203):

@kgallspark @JamesWigglesworth 
As we discussed the other day, it's silly to have specific set modes. It's better to simplify the setting of the values in common ways. These can still be adjusted with individual 'w' or 'S' commands after the main command, but as long as our new 'S' command can reproduce the existing DDE mode sets when given the correct parameters, it will satisfy the letter of the Monty request and also give users a tool that they can use to set "submodes" that smoothly transition from one preset mode to another and hopefully will give them all sorts of different capacities for load and "feel" when moving the arm.

Take a look at this spreasheet which I made from DDE's mode set commands. 
https://docs.google.com/spreadsheets/d/1bf2u-hSuzWSXB12lu0_LHWHDlJ-iFqffg0sEph-rPU4/edit#gid=0

It looks to me like there are 11 parameters that cover all the variations between the modes.  I've highlighted those with the tan colored lines. So, for example, if you pass in a DIFF_FORCE_SPEED_FACTOR_ANGLE of 8, that's what DDE would do to put you in "Follow" mode, if you pass in a 3, that's like "Protect" mode. But now, you can choose other values. I can see that being more useful with the PID, Friction, and Force Decay values. 

We can then document for them some general guidelines. Like "If the arm starts to shake with a heavier load, increase PID XYZ." Or whatever.

Given the size of the socket buffer, that /might/ just fit, but it would be really good to try to combine / reduce the numbers. For example, do we really need 4 different Friction settings, or can we set Base, XYZ, and Wrist like we do for PID? Or do we really need separate Base and XYZ PID values? Base and XYZ seem to always be set the same.

Questions:
1. Are there other parameters we should include?

2. Are there settings we should not be changing? e.g. is DIFF_FORCE_MAX_SPEED needed? (I already pulled all the timebase stuff)

3. Are there settings we can reliably calculate from other settings or via a new parameter? E.g. can "Load Mass" be used to calculate the PID settings?

4. What are the default settings for the missing items in the columns to the right? I've marked those with red question marks.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-08-25 02:09](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-415924213):

Progress:
https://github.com/HaddingtonDynamics/Dexter/commit/f0d9fa772ba6c3eee979e62a071bca487a084c21

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-08-26 01:58](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-416008371):

My next release will have support for Dexters of an unlimited joint count
in some cases, and at least 7 in others.
I know some programming by example uses of Dexter have used the
width of the grippers manually manipulated (j7) and probably J6 as well.
In one case at the above URL, there is a link length section
that takes just 5 numbers and a
"fric" setting that takes just 5 numbers.
I'm nervous that we'll paint ourselves into a corner and make
backward compatibility difficult in the face of expansion.
In general, this problem isn't really solvable. We will often
have to put some stakes in the ground and live with them.
But at least for high level cmds like "move_all_joints",
its now not limited in the number of joints it accepts
(err, except packet size I guess).


On Fri, Aug 24, 2018 at 10:09 PM JamesNewton <notifications@github.com>
wrote:

> Progress:
> f0d9fa7
> <https://github.com/HaddingtonDynamics/Dexter/commit/f0d9fa772ba6c3eee979e62a071bca487a084c21>
>
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-415924213>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITfRn0ByUysDeMfTSoz3HuijGMXrSDks5uULHjgaJpZM4Vy-ay>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-04 21:48](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-418529231):

Release:
https://github.com/HaddingtonDynamics/Dexter/commit/f0d9fa772ba6c3eee979e62a071bca487a084c21
effectively provides this ability. From the release notes:

Line 4343: Add SetParm ("S") sub-command "Ctrl" which takes named parameters and quickly sets commonly used values. The named parameters are:
- `PIDP # # # ` - sets the PID P value for the BASE to the first number, the END, and PIVOT to the next, and ANGLE and ROT to the last. This controls how hard the arm reacts to an error in the joint position. Too high a value may cause it to shake, too low will cause inaccurate positions.
- `Frict` # # # # # ` - sets each joint friction values. These are floating point. This controls how hard it is to move any joint.
- `Diff # ` - sets the DIFF_FORCE_SPEED_FACTOR_ANGLE and DIFF_FORCE_SPEED_FACTOR_ROT to the specified value
- `FMul # ` - sets SPEED_FACTORA. Multiplier (coefficient / master gain) for the force calculator. 
- `Decay # ` - sets the *_FORCE_DECAY for all joints to the same number. This is how hard the arm tries to return to the commanded position.
- `Cmd # ` - sets the command register. 

For example: An S command with 
"Ctrl Diff 3 FMul 10 PIDP 1045351628 1045351628 1022739087 Frict 2 3 9 15 15 Decay 9000 Cmd 12448" 
would set a Protect mode and 
"Ctrl Diff 8 FMul 30 PIDP 0 0 0 Frict 5 5 5 15 15 Decay 0  Cmd 12448" would set a "Follow" mode. 

Note that the total command length, including the job and instruction number, start time, end time, command letter, and all the parameters, can not exceed 128 character. That leaves approx 90 characters for the Ctrl command string. 

Future named parameters may simplify settings. E.g. a `Mass` value could possibly set the PID drive based on the mass of the object being lifted.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-09-04 23:03](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-418545273):

In the example, it would be helpful if it
included a complete example from DDE, ie
something that starts with
make_inst("S" ....)

On Tue, Sep 4, 2018 at 5:48 PM JamesNewton <notifications@github.com> wrote:

> Closed #33 <https://github.com/HaddingtonDynamics/Dexter/issues/33>.
>
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/33#event-1826421058>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITffYzpENUunH_LCscd-dJ5Uh3dhVBks5uXvUugaJpZM4Vy-ay>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-12 22:34](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-420820420):

https://github.com/HaddingtonDynamics/Dexter/commit/361d65dfb0b22d1907449a4e814349a7571e0577
Just makes this a bit easier by ignoring JSON formatting characters. E.g. instead of having to do 
`PID_P 1,2,3`
you can do 
`[PID_P: 1, 2, 3]`
and the firmware won't see any difference.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-12 22:36](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-420821058):

> In the example, it would be helpful if it included a complete example from DDE, ie something that starts with make_inst("S" ....)

This normally wouldn't be done from DDE as DDE has other ways of setting it, but, one example (from the spreadsheet above) would be:

`make_inst("S Ctrl Diff 8 FMul 30 PIDP 0 0 0 Frict 5 5 5 15 15 Decay 0  Cmd 12448")`

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-08 17:44](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-427921288):

Our documentation didn't make it clear that the numbers for the PIDP values are actually IEEE 32 bit floating point numbers, being passed in from DDE as integers. To make reasonable changes to these values, we need to develop, document, and then automate the process of starting with the desired floating point value, converting that to a binary representation ala IEEE 754 and then convert that to a decimal number to send to DexRun. Once we have that process, we can amend the Ctrl command to accept Floating Point values directly.

https://en.wikipedia.org/wiki/Single-precision_floating-point_format#IEEE_754_single-precision_binary_floating-point_format:_binary32

The website at:
https://gregstoll.dyndns.org/~gregstoll/floattohex/
can be used to do the conversion. So, for example, the "pidBase" variable from DDE used to enter Follow mode, which is represented as 0x3e4ecccc (hex) in the Javascript, and sent to DexRun as 1045351628 (decimal) but actually represents a floating point 0.2

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-13 02:50](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-429505344):

Commit https://github.com/HaddingtonDynamics/Dexter/commit/e3cccb88cf9b1671c5b2f13c77d1ee00a967a528 Adds support for seting the PID P values using floating point, via the [J#_PID_P parameters to the SetParam oplet](https://github.com/HaddingtonDynamics/Dexter/wiki/set-parameter-oplet) e.g. `S J1_PID_P 0.2` To avoid breaking backward compatibility, the floating point support was NOT added to the Ctrl parameter or the 'w' oplet / write command, but instead:

To support single command mode setting (and much more) the [RunFile parameter for the SetParam oplet](https://github.com/HaddingtonDynamics/Dexter/wiki/set-parameter-oplet) is a replacement for Ctrl with several advantages:
1. It has no length limit.
2. It can perform ANY full S or w command without abbreviation.
3. It can perform ANY standard oplet/command period... even moves. Even calibrate. Or demos. Or running other files. 
4. It can still do all that in one command because it pulls the instructions from a file on the robot e.g. `FollowMode.make_ins`

For now, both RunFile and Ctrl are still available.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 23:03](https://github.com/HaddingtonDynamics/Dexter/issues/33#issuecomment-722021646):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/33)


-------------------------------------------------------------------------------

# [\#32 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/32) `closed`: Write strings on the Dynamixel bus
**Labels**: `Firmware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-08-03 04:22](https://github.com/HaddingtonDynamics/Dexter/issues/32):

In order to support more complete IO via the Tinyscreen+ on the v2 Tool Interface, it would be very good to be able to send it strings of data instead of just 4 bytes at a time.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-08-03 04:54](https://github.com/HaddingtonDynamics/Dexter/issues/32#issuecomment-410144296):

Would it be a good idea to be able to send such strings from DDE?
Mostly I suspect no, but this *could* be used to test the
connectivity to the tinyScreen.

Also, if the computer running DDE was remote from
the Dexter, its a way that a dde programmer could
communicate with the Dexter operator.

I'd guess we'd need a new oplet for this,
though perhaps a "set_parameter" to "tiny_screen_display" could work.

On Fri, Aug 3, 2018 at 12:22 AM, JamesNewton <notifications@github.com>
wrote:

> In order to support more complete IO via the Tinyscreen+ on the v2 Tool
> Interface, it would be very good to be able to send it strings of data
> instead of just 4 bytes at a time.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/32>, or mute the
> thread
> <https://github.com/notifications/unsubscribe-auth/ABITfcgC4WpltxNmRnrVSEj9XDEIzn7uks5uM9AcgaJpZM4VtWxy>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-08-03 20:38](https://github.com/HaddingtonDynamics/Dexter/issues/32#issuecomment-410370014):

It is set_parameter. See the documentation (just updated) at 
https://github.com/HaddingtonDynamics/Dexter/wiki/End-Effector-Screen
towards the bottom.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-08-03 21:37](https://github.com/HaddingtonDynamics/Dexter/issues/32#issuecomment-410382880):

Great.
I tried way back when to be able to move a string from
DDE to become an arduino program and failed.
Maybe we can take another whack at it,
as it would be nice to just edit a file in DDE
then shove it into the TinyScreen.

Nice set of utility functions.
Let's talk about incorporating those into DDE.
We can put a "class" around them,
make a section of the Ref Man for them
and do a little language smithing.

I presume we'll want to figure out how
to get a button click back from the TinyScreen
which will be a challenge, but maybe we
can at least map out potentially desirable functionality
to give ourselves some guidelines.

On Fri, Aug 3, 2018 at 4:38 PM, JamesNewton <notifications@github.com>
wrote:

> It is set_parameter. See the documentation (just updated) at
> https://github.com/HaddingtonDynamics/Dexter/wiki/End-Effector-Screen
> towards the bottom.
>
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/32#issuecomment-410370014>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITffPOUfp0fM-86Tfzj6xzt4MaTwwlks5uNLTWgaJpZM4VtWxy>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-08-03 21:42](https://github.com/HaddingtonDynamics/Dexter/issues/32#issuecomment-410383904):

We have a dedicated return data line from the Tinyscreen+ to the FPGA, but no USART in the FPGA to read it yet. Thanks for the reminder, that's another issue. And we need to extend read_from_robot to read back FPGA data as well. @JamesWigglesworth and I just got a data (vs file) readback to work on that the other day, so it shouldn't be terribly hard. It's issue #11

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-05-24 19:24](https://github.com/HaddingtonDynamics/Dexter/issues/32#issuecomment-495762108):

Implementation of Dynamixel communications was moved from the FGPA to DexRun.c. The `SendWrite1Packet` function needs to be updated to accept a char array rather than a single char.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 23:02](https://github.com/HaddingtonDynamics/Dexter/issues/32#issuecomment-722021206):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/32)


-------------------------------------------------------------------------------

# [\#31 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/31) `open`: Remote operation of Dexter via Internet
**Labels**: `communication`, `enhancement`, `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-08-01 00:05](https://github.com/HaddingtonDynamics/Dexter/issues/31):

It will be desirable to operate Dexters remotely via the Internet either to monitor, operate, and/or repair remote devices, or to make Dexters available for general purpose work. 

Dexter supports socket connections natively, but those are typically limited to the local internet and do not pass through firewalls without additional (and often not allowed) holes being opened. WebSockets can operate freely between most networks, but despite the name, are NOT the same as native socket connections. WebSocket connections can be supported on the Dexter via a [simple NodeJS proxy server](../wiki/nodejs-webserver), but getting out to the internet requires "chat" server accessible from the internet in general. The local Dexters NodeJS server would connect to the DexChat server, registering the robot as active and opening a WebSocket connection. Humans would log into the DexChat server via browser which would be served a web page which would then open WebSocket connections. The DexChat server would list available robots, perhaps filtering the list according to access rights. 

The human could initiate a connection to the robot through the DexChat server. Messages would go to the server, which would then relay it to the open WebSocket connection to that Dexter. The NodeJS server on the Dexter would receive the message, relay it as a true socket message to the firmware on localhost, pick up the response, and relay it back to the chat server via websocket. The chat server would then relay that back to the human via the websocket connection to the browser. This is basically, like a Private Message on a standard chat server.

The major concern here is the speed of the connection. The NodeJS Proxy server takes about 1.6ms between Dexter and a Chrome web browser. Because [NodeJS is known for very rapid response times](https://github.com/hashrocket/websocket-shootout/blob/master/results/round-02.md) and we are a JavaScript heavy house, we will try that first. 

But as we move out into the internet, latency of hundreds of ms are not unknown. As a result, Dexters haptic feedback system can get into oscillations or just lag, causing touch feedback to become unusable. The solution is probably to work towards predicting the next movement when sending data from the robot with the human, and predicting forces when sending data back. Obviously, the former is easier than the latter, but 3D scanning the work area and proximity detection before actual touch can help.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-08-01 00:05](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-409406395):

# Compute Engine / Websockets attempt: #
Failed:
-DDE can't connect to Self Signed Certs, 
-Compute Engine w/ Node doesn't support Websockets.

Because Google cloud services provides a few free hours each month, we will try to spin up on that platform. As far as we can tell, Google supports WebSockets via the Compute Engine, and [on the Flexible version of App Engine](https://cloud.google.com/appengine/docs/flexible/nodejs/using-websockets-and-session-affinity). Since the compute engine will support anything, [including nodejs](https://cloud.google.com/nodejs/docs/tutorials/bookshelf-on-compute-engine), that's probably the best place to start.

A server has been setup generally following this guide:
https://medium.com/google-cloud/node-to-google-cloud-compute-engine-in-25-minutes-7188830d884e _(note to self: Under Compute Engine, VM instances, when you can't find the SSH link, scroll right.)_
There were a few minor changes needed:
- When "Installing Node", the command `sudo apt-get install -y nodejs npm` errors with "Some packages could not be installed. This may mean that you have requested an impossible situation or if you are using the unstable distribution that some required packages have not yet been created or been moved out of Incoming." These days, installation of node via NVM is a better choice. e.g. the command `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.1/install.sh | bash` gets us NVM and then with NVM working, `nvm install stable` gets us node.js and npm. 
- "Gulp is used for building both the client and server from the /src/ folder. By default, it watches for file changes in server and client and will rebundle/restart as necessary." This makes development faster, because you don't have to actively push changes; they just happen. When installing Gulp, we run into incompatibilities between it and node 12, as described in 
https://stackoverflow.com/questions/55921442/how-to-fix-referenceerror-primordials-is-not-defined-in-node/56328843#56328843
The best fix seems to be dropping back to node version 10, aka "Dubnium" which shouldn't [EOL until 2021-04-30](https://nodejs.org/en/about/releases/). 
- `npm run build-prod` may need to be `npm run build` (don't remember which worked).
- [pm2](https://pm2.keymetrics.io/docs/usage/quick-start/#check-status-logs-metrics) keeps everything running as per it's [application](https://pm2.keymetrics.io/docs/usage/application-declaration/) file which using the .json format and, lets us view log files: `pm2 logs` , monitor operation: `pm2 monit`, etc.. 

The end result is a [Debian 9.2 "Stretch"](https://packages.debian.org/stretch/) based Linux OS and node / express with react server via node reverse proxy. The source file are:
https://github.com/ColeMurray/react-express-starter-kit
You can add content in multiple places:
- node / express is setup in `react-express-starter-kit/app/server/index.js` but that file supposedly gets copied in from `react-express-starter-kit/src/server/index.js`? In any case, it's express, so adding new ["middleware"](https://expressjs.com/en/guide/using-middleware.html) should be pretty easy. Note: Changes to the underlying files (e.g. the server/index.js) seems require a `pm2 start pm2config.json` to have effect although gulp should be doing that automatically.

- react is... popular... and may be of use. The code that runs on the client (browser) is in `react-express-starter-kit/src/client/index.js` and the code for the server is in `react-express-starter-kit/src/server/index.js` as previously noted. For more see:
https://reactjs.org/docs/introducing-jsx.html

- Raw html is in `react-express-starter-kit/public/` The `index.html` is default and is setup as a template for react. 

- nginx site config is in `/etc/nginx/sites-available/default` and it proxy's from the node express server running on port 8080. Another proxy could probably be setup... See:
https://medium.com/@utkarsh_verma/configure-nginx-as-a-web-server-and-reverse-proxy-for-nodejs-application-on-aws-ubuntu-16-04-server-872922e21d38 
for more info on how that all works. Restart via `sudo service nginx restart`. 

Security: It is critical to not just allow a chat server to exist out in the world without encryption and user login; otherwise any sort of human communication /will/ be used to distribute porn. We could try tightly constraining the allowed messages to those that Dexter firmware can support, but that would limit our ability to connect to the job engine. User log in, and therefore encryption is critical to avoid the chat server being used for "bad things". Sadly, decrypting and encrypting data WILL slow down the connection. Perhaps a combination approach can work? Very tightly constrained message types consisting of joint angle / torque data can flow plain text, and other more general user interface items can be encrypted and unrestricted. 
- A self signed certificate is installed for https encryption as per:
https://www.digitalocean.com/community/tutorials/how-to-create-an-ssl-certificate-on-nginx-for-ubuntu-14-04
It's locked to the IP address (no dns to avoid attracting attention and because I don't have access to the domain name servers) and so will still warn everyone that the domain doesn't match. It is self signed so the browser will reject it; go to advanced, and then "Proceed..." to use the encrypted connection. 
- With the cert in place, the nginx config is changed to [re-direct all http requests to https](https://serversforhackers.com/c/redirect-http-to-https-nginx) by creating a seperate server for port 80 and just 301ing every request to the other server on 433: 
```
server {
  listen 80;
  server_name _;
  return 301 https://$host$request_uri;
}
```
Note that this can NOT be done in the express app because at that point, express is seeing a request to 127.0.0.1:8080 not to the external ip address.

To avoid constant re-transmission of passwords, we need to support session level authentication. This seems like a good starting point:
https://github.com/Createdd/Writing/blob/master/2017/articles/AuthenticationIntro.md
- body-parser comes with express now, and so doesn't need to be installed. 
- `npm install express-session` Manages sessions for express.js.
- `npm install connect-mongo` Stores the session data in mongodb.
- Installing mongodb didn't seem as complex as [their site](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/) makes it... but it IS! `sudo apt-get install mongodb`. Appears to work, but once that finishes, `sudo service mongod start` fails to start the damon as a service. _sigh. Note to self, follow the instructions._ And after not following their instructions, then following their directions fails because of the leftover tools that are installed. It was necessary to [uninstall everything](https://askubuntu.com/a/1107604/407288), then re-install.  Now the service starts with `sudo service mongod start`. `mongo` gets you into their command line system.  `use testForAuth`, `db.users.find()`, `db.users.updateOne({email:"gooduser@hdrobotic.com"},{$set:{approved:true}})`, etc... To make it automatically start on boot: `sudo systemctl enable mongod.service`
- [mongoose](https://mongoosejs.com/docs/) makes it easy to use mongodb in express.js. Install results in multiple warnings of DoS issues with regexps (...now they have two problems) and "Prototype Pollution" [^](https://www.npmjs.com/advisories/577) [^](https://www.npmjs.com/advisories/782) [^](https://www.npmjs.com/advisories/1065) . Those that could be fixed with no bad side effects were fixed with `npm audit fix`. 
- bcrypt provides local encryption of the stored passwords. It [isn't pre-built for Debian](https://github.com/kelektiv/node.bcrypt.js/wiki/Installation-Instructions) sadly.  The actual binary for bcrypt is easy to install: `sudo apt-get install bcrypt` but the node package isn't. However, there are [instructions for installing the stuff required to build it locally](https://github.com/kelektiv/node.bcrypt.js/wiki/Installation-Instructions#ubuntu-and-derivatives---elementary-linux-mint-etc) and that seems to work. 
Note: If you update node, you /must/ `npm rebuild bcrypt --update-binary` with that extra update binary flag AND you must restart the VM or otherwise somehow get the binary out of RAM. Bloody nightmare. It might be better to use bcryptjs?

A test file `make_user_db.js` shows that the above is working outside express. 

The complexity of session management is well explained by this video:
https://www.youtube.com/watch?v=OH6Z0dJ_Huk

Finally ready to add web sockets:
- `npm install ws` . Then get [ws working with express](https://github.com/websockets/ws/tree/master/examples/express-session-parse) The tricky bit is mapping the session data to the web socket. And for that, we can use a Map(). And that will be our list of users. 

And.... web sockets don't work on Compute Engine when using node.js (can use python). But more importantly, you can't connect to the server using a self signed certificate via DDE. At this point, the decision was made to go on to App Engine instead since it provides a valid certificate. It also doesn't support web sockets, but HTTP and BOSC might work.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-20 22:04](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-423349126):

Because it's faster, and lighter, we are using:
https://github.com/websockets/ws
instead of Websocket.IO. Also, I couldn't get it to install on Dexter. ,o)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-21 00:11](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-423373750):

For access to the webcam, this works for still pictures, but is very slow (e.g. 2 frames per second, at 320x200)
https://github.com/chuckfairy/node-webcam
It requires installation of an external program:
`sudo apt-get install fswebcam`

Part of the issue may be that fswebcam wants to save every frame to hard drive (sdcard in our case). This may help
https://github.com/chuckfairy/node-webcam/issues/10
It appears that fswebcam can return the image data to stdout when given a special filename via an option: `--save '-'`
https://github.com/fsphil/fswebcam/issues/11
But initial testing shows that isn't much faster.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-04-26 00:31](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-486883910):

Installed the ZeroTier client in Dexter:
https://www.zerotier.com/download.shtml
via 
`curl -s https://install.zerotier.com/ | sudo bash`
which reports: `*** Success! You are ZeroTier address [ 5f6280cf58 ].`

However, it strikes me that this is completely useless because now EVERY Dexter that is put out there will think it's that ZeroTeir address. In fact, doesn't installing ZeroTier need to be re-done on each robot AFTER the image is updated? Or at least, it needs to be triggered to go get a new address. But how? This question has been asked of their community:
https://community.zerotier.com/zerotier/pl/s5waqqpxcp8gbfemckgz1odxsy

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-04-26 05:25](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-486930205):

ZeroTeir says:

If you remove /var/lib/zerotier-one/identity.secret and /var/lib/zerotier-one/identity.public from your base image, a unique identity will be generated the first time zerotier starts.

So that should sort it... before making the image, we can delete those items, then when the image is started in a new robot, and it's connected to the internet, it should go and get a new address. 

Started a checklist for making a new image and added this instruction to it:
https://github.com/HaddingtonDynamics/Dexter/wiki/SD-Card-Image#checklist-for-making-new-image

#### <img src="https://avatars2.githubusercontent.com/u/355654?v=4" width="50">[Scott C. Livingston](https://github.com/slivingston) commented at [2019-07-15 02:16](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-511257319):

is there any new progress to report about this?

soon I will finish assembling the Dexter HD kit. later this month, I plan to share it via the Internet through a system that I am building, <https://rerobots.net/>

I am happy to contribute benchmarks, discuss use-cases, etc. so we can explore together good methods for accessing Dexter remotely.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-11-06 02:23](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-550112302):

To reduce latency, relay (e.g. chat) servers must be able to "punch through" NAT and allow peer to peer communications. I haven't been able to get Zero Tier to work. It's VERY complex. This seems simple, and would be a good test:
https://github.com/SamDecrock/node-tcp-hole-punching

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-06 22:46](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-595996956):

https://docs.husarnet.com/info/
Appears to be doing more or less what we want to do in terms of connecting things across networks. Although they say it always goes peer to peer in other places, in their documentation, they admit that each peer to peer option can fail if the firewall is tight. e.g.

> - First, the Husarnet client connects to the base server (via TCP on port 443 and optionally UDP on port 5582) hosted by Husarion. Husarions runs multiple geographically distributed base servers.
Initially the encrypted data is tunnelled via the base server.
> - The devices attempt to connect to local IP addresses (retrieved via the base server). This will succeed if they are in the same network or one of them has public IP address (and UDP is not blocked).
> - The devices attempt to perform NAT traversal assisted by the base server. This will succeed if NAT is not symmetric and UDP is not blocked on the firewall.
> - The devices send multicast discovery to the local network. This will succeed if the devices are on the same network (even if there is no internet connectivity or the base server can't be reached).

TODO: Try this on a Dexter. Note it doesn't support Windows PC's or Node. It needs to be installed in Linux. I still think a websockets version, although slower, will be better in the long run because it supports higher level communication between controlling PCs, which provides access to the resources of the PC.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-20 00:37](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-601478737):

# Jitsi Attempt #
Failed:
- Jitsi's codebase is designed to work ONLY in a browser environment. Even their Electron app is a simple interface to the code running in a browser instantiated in the app. 
- Their documentation is /zero/ except for how to setup Jitsi on a server.

Jitsi is a full open source, 
https://github.com/jitsi/jitsi-meet
and provides an _excellent_ user experience for video, audio, and text chat. It is, at heart, a node.js based NPM installed service, but it uses other systems for video and audio.<sup>[1](https://github.com/jitsi/jitsi-meet/blob/master/doc/manual-install.md)</sup> All of that gets installed<sup>[2](https://github.com/jitsi/jitsi-meet/blob/master/doc/quick-install.md)</sup> on a server, which we can do at some point in the future, but do NOT need to do now because:
https://meet.jit.si/
is up and running and does NOT require any user account, payment, or other BS to start using. 

The goal would be to allow DDE or a Unity app to join a meet.jit.si meeting and then send and receive chat messages with each other. 

There is an API for embedding in your own application
https://github.com/jitsi/jitsi-meet/blob/master/doc/api.md
But I can find no mention of how to send text messages in that API... 

Looks like the core of this is UV4L and with a few things added to an rPi, the rPi can create and join Jitsi meetings without a browser, so this IS possible.
https://www.linux-projects.org/uv4l/tutorials/jitsi-meet/

Jitsi uses [XMPP](https://en.wikipedia.org/wiki/XMPP) over [BOSH](https://en.wikipedia.org/wiki/BOSH_(protocol)). Apparently we can " join the muc myroomname@conference.mydomain.com". I assume that would be something like roomname@meet.jit.si and we would connect via BOSH and then use XMPP to "sent the message to the participant you want". Apparently, XMPP over BOSH is sort of it's own thing called XEP-0206. I can't find any NPM packages for that, and searching for XMPP BOSH finds a number of packages for a specific service called pubnub which does not appear to be FOSS. The best match I can find seems to be:
https://www.npmjs.com/package/strophe.js

#### Communications: XMPP / Jabber
The specification for XMPP in MUC's (Multi-User Chat) is found at:
https://xmpp.org/extensions/xep-0045.html

So what I get from this is that they have a format of:
`room@service/nick` where "nick" is the user name in the room only, not the actual user name, "room" is one specific meeting room or identifier for a video call, and "service" is the host domain. 

So if it were "James Newton" in 
httpd://meet.jit.si/massmind then they would say
`massmind@meet.jit.si/James%20Newton`
It's probably best to avoid nicknames with spaces while we are starting.

They call `room@service/nick` the JID. I'm guessing that JID is "Jabber ID" since this used to be called Jabber.

"A user enters a room (i.e., becomes an occupant) by sending directed presence to <room@service/nick>."

"An occupant exits a room by sending presence of type "unavailable" to its current <room@service/nick>."

Section 6.4 is how to ask a room what features it supports. We want to make sure it's not private or requiring a login. This probably isn't required, at least not at first. 

Section 7.2.1 shows how to join a room:
````
<presence
    from='hag66@shakespeare.lit/pda'
    id='n13mt3l'
    to='coven@chat.shakespeare.lit/thirdwitch'>
  <x xmlns='http://jabber.org/protocol/muc'/>
</presence>
````
So the `<x xmlns='http://jabber.org/protocol/muc'/>` just says "I'm speaking your language". the to= appears to be talking about room@service/user which I think means this is a user known as "hag66@shakespeare.lit/pda" wants to be known as "thirdwitch" joining a MUC in a room called "coven" on the "chat.shakespeare.lit" server. Apparently the from field is required? But on Jitsi there is no user signup, so do we just make that up? I think the id is just a random string to make sure messages don't get misrouted. 

Section 7.5 is sending a private message to another user in the MUC
````
<message
    from='wiccarocks@shakespeare.lit/laptop'
    id='hgn27af1'
    to='coven@chat.shakespeare.lit/firstwitch'
    type='chat'>
  <body>I'll give thee a wind.</body>
  <x xmlns='http://jabber.org/protocol/muc#user' />
</message>
````
So here, it appears that the from= is the users real id, but the server will replace it with the nick "thirdwitch" (which they had used to join the room) before sending the message on to the to= user. The to= starts with the current room/server and the nick for the intended destination just gets added to that. So then the message gets sent to the nick "firstwitch" which the server happens to know is actually crone1@shakespear.lit/desktop. 
````
<message
    from='coven@chat.shakespeare.lit/secondwitch'
    id='hgn27af1'
    to='crone1@shakespeare.lit/desktop'
    type='chat'>
  <body>I'll give thee a wind.</body>
  <x xmlns='http://jabber.org/protocol/muc#user' />
</message>
````
It's possible that this is all we need to know about the room system. 

#### Connection: BOSH / Strophe / meet.jit.si

The connection part of the puzzle has been much harder to figure out. BOSH is relatively easy to understand, but the documentation for Strophe is massive, but nearly devoid of examples, and there is ZERO documentation on how to connect to meet.jit.si. An issue has been raised:
https://github.com/jitsi/jitsi-meet/issues/5559

Requests for help in their community have been met with cryptic and terse responses:
https://community.jitsi.org/t/inserting-locally-connected-device-data-into-chat/24118/3
a new, more forceful, request has been made:
https://community.jitsi.org/t/authentication-fail-on-connect-but-jitsi-doesnt-require-authorization/28566

At this point, When we run the code below, we get 

1 CONNECTING
3 AUTHENTICATING
2 CONNFAIL
6 DISCONNECTED

```
var conn = new Strophe.Connection("https://meet.jit.si/http-bind")
conn.connect('massmind@meet.jit.si/cfry', //fake jid, that's ok right?
             "", //don't need password?
             function(status_code) { //status_code is a small non-neg integer
                   console.log("connected with status: " + status_code + " " + strophe_status_code_to_name(status_code))
             }) 

```
So an authentication failure? This is very confusing since jitsi doesn't require any authentication... 

In the end, if we can't figure out how to make the connection, we will need to just move on and find some other way to do this. It's a crying shame as Jitzi being FOSS is just taylor made!

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-05-24 05:08](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-633180367):

# App Engine attempt #
Status: Working via BOSC

This is a pretty standard node / express server:
````js
const express = require('express')
const http = require('http')
const WebSocket = require('ws') //https://github.com/websockets/ws
const bodyParser = require( "body-parser") //parse post body adata
const bcryptjs = require('bcryptjs') //to encrypt passwords for storage

const app = express()
const PORT = 8080
````

For node.js on the app engine, there are two environments: Standard and Flexible. 
https://cloud.google.com/appengine/docs/nodejs
https://cloud.google.com/appengine/docs/the-appengine-environments
To reduce ongoing cost of operation, we are starting with the standard environment. Sadly, that does not support websockets, which would be very easy to use, but, luckily Jitsi taught us about BOSC

https://en.wikipedia.org/wiki/BOSH_(protocol)
BOSC support server push notifications by simply not responding to a request from the client until the server has something to send to the client. The request simply hangs until data arrives (via another connection to the server from the sender) or until it times out. In either case, it is the clients responsibility to re-establish the request as quickly as possible and so continue listening for data from the server, or more accurately from a sender via the server.

The other issue with the Standard Environment is that it can be shut down and started up at Googles will. This makes keeping session state interesting. You can log in, get a cookie, and if that cookie was stored in a local RAM session store, it can be forgotten at any moment. Luckily, [`google/@datastore`](https://www.npmjs.com/package/@google-cloud/datastore) supports using a Cloud Firestore in Datastore mode as the store. 
````js
const {Datastore} = require('@google-cloud/datastore');
const session = require('express-session') //session mgmt
const DatastoreStore = require('@google-cloud/connect-datastore')(session);
````
````js
const data_store = new Datastore({
      // @google-cloud/datastore looks for GCLOUD_PROJECT env var. Or pass a project ID here:
      // projectId: process.env.GCLOUD_PROJECT,
      projectId: APP_ENGINE_PROJECT_ID,
      // @google-cloud/datastore looks for GOOGLE_APPLICATION_CREDENTIALS env var. Or pass path to your key file here:
      keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS
    })

//Session setup seperate sessionParser so 
app.use(session({
  store: new DatastoreStore({
    kind: 'express-sessions', 
    // Optional: expire session after exp milliseconds. 0 means do not expire
    // note: datastore doesnt auto del expired sessions. Run separate cleanup req's to remove expired sessions
    expirationMs: 0,
    dataset: data_store
  }),
  resave: false,
  saveUninitialized: false,
  secret: 'Like id tell you'
}));
````
The only problem with that is that cookies are perminant and do not expire, even if you tell them to. It's necessary to manually clear out the 

````js
//just serve up static files if they exist
app.use(express.static('public')) 
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({extended: true}))

/* Authentication section removed, it basically just sets a user name
req.session.user = username
*/
````

Rather than use available BOSC packages (which were poorly document and very confusing) a microscopic version of BOSC was included. For this service, we can be relatively certain that the engine will not be shut down, because it's always pending a BOSCout request. As long as one listener is listening, google doesn't have time to shut down the engine and therefore drop the `boscs` array. 

Operation: BOSCout requests come in, get added to the boscs array, and then nothing else is done. There is no reply, no error, no nothing. This causes the socket to stay open, as the client waits for the server to respond. Next, a BOSCin request comes in, with a "to" parameter for the user who made the BOSCout request. Since that user is found in the boscs array, the socket response object can be found, and the message sent to that client. The entry in the boscs array is then deleted so it won't be found by another BOSCin until the BOSCout client re-establishes the connection. 

````js
//MicroBOSC
var boscs = {}
BOSCtimeout = 30000 //in milliseconds

app.get('/BOSCout', function (req, res, next) { 
  console.log("BOSCout,  user:"+req.session.user)
  if (!req.session.user) {
    var err = new Error('FAIL: Login')
    err.status = 403
    next(err) //skips to error handler. 
    }
  boscs[req.session.user]={}
  boscs[req.session.user].res=res
  boscs[req.session.user].int=setTimeout(function(){ 
        //console.log('BOSCout timeout '+req.session.user)
        res.status(408)
        res.send('BOSCout timeout')
        res.end()
        delete boscs[req.session.user]
        return
    }, BOSCtimeout)
//dont reply or end. 
return
})

app.get('/BOSCin', function(req,res, next) {
    //Check that the requestor is logged in. 
    if (!req.session.user) {
        var err = new Error('FAIL: Login')
        err.status = 403
        next(err) //skips to error handler. 
        }
    let msg = req.query.msg || "none"
    let to = req.query.to
    let bosc = {}
    //parameter is the session.user to send the message to
    if (to) { //console.log("to "+to)
        if ( boscs[to]) { console.log("found")
            bosc = boscs[to] //lookup session id from username
            }
        }
    bosc.stat = "unknown"
    if (bosc.int) { //console.log("clearing timeout")
        clearInterval(bosc.int)
        bosc.int=undefined
        }
    if (bosc.res) { //console.log("responding")
        bosc.res.setHeader("from_user", req.session.user)
        bosc.res.send('BOSCin message:' + msg) //don't change w/o Fry.
        bosc.res.end()
        bosc.stat = bosc.res.headersSent ? "good" : "bad" 
        //https://expressjs.com/en/4x/api.html#res.headersSent
        //bosc.res = undefined //make sure we know this response object is used
        delete boscs[to]
        }
    console.log("to:"+req.query.to+". stat:"+bosc.stat+". ")
    res.send('BOSCin to:' +req.query.to + ". Status:" + bosc.stat) 
    res.end()
})
````

If the user requested in the BOSCin is not found in the boscs array, "unknown" is returned to the BOSCin client. Otherwise, "good" is returned. 

The rest of the code is just the standard node / express setup:

````js
// If we get here, the file wasn't found. Catch 404 and forward to error handler
app.use(function (req, res, next) {
  var err = new Error('File Not Found');
  err.status = 404;
  next(err);
});

// Error handler define as the last app.use callback
app.use(function (err, req, res, next) {
  res.status(err.status || 500)
  res.send(err.message)
  })

app.listen(PORT)
````

Support for this server is being added to DDE via the Messaging class.

Testing shows throughput rates of 50ms and latency of 80ms (which is _amazing_) to 300ms under normal use. 

All code archived here:
https://drive.google.com/drive/u/0/folders/18OgYsn8LLy1IkCCo-7XHSYZBMB5R-nhN

NOTE: THIS IS VERY LIKELY TO CHANGE!

TODO: Fix issues with session cookies lasting forever

TODO: Add a means of registering new users and ensuring they are Dexter users. 

FAIL: Try UDP as a faster option, when the router allows datagrams to NAT back. Although it looked like this was possible, it appears it is NOT on the standard app-engine. They don't explicitly say you can't for node.js (there is no page about it for node) but they DO say you can not accept inbound connections on the python page, and can no longer do outbound. [1](https://cloud.google.com/appengine/docs/standard/python/sockets#limitations-and-restrictions) If we want to do UDP, we need a REAL server with control of the firewall.

TODO: Transition to Flexible environment or a real server and re-enable websockets.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-06-04 04:25](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-638594403):

## Mosh / SSH -R

SSH has some interesting command line options. 

````

     -T      Disable pseudo-terminal allocation.

     -R [bind_address:]port:host:hostport
     -R [bind_address:]port:local_socket
     -R remote_socket:host:hostport
     -R remote_socket:local_socket
             Specifies that connections to the given TCP port or Unix socket
             on the remote (server) host are to be forwarded to the given host
             and port, or Unix socket, on the local side.  This works by allo‐
             cating a socket to listen to either a TCP port or to a Unix
             socket on the remote side.  Whenever a connection is made to this
             port or Unix socket, the connection is forwarded over the secure
             channel, and a connection is made to either host port hostport,
             or local_socket, from the local machine.

             Port forwardings can also be specified in the configuration file.
             Privileged ports can be forwarded only when logging in as root on
             the remote machine.  IPv6 addresses can be specified by enclosing
             the address in square brackets.

             By default, TCP listening sockets on the server will be bound to
             the loopback interface only.  This may be overridden by specify‐
             ing a bind_address.  An empty bind_address, or the address ‘*’,
             indicates that the remote socket should listen on all interfaces.
             Specifying a remote bind_address will only succeed if the
             server's GatewayPorts option is enabled (see sshd_config(5)).

             If the port argument is ‘0’, the listen port will be dynamically
             allocated on the server and reported to the client at run time.
             When used together with -O forward the allocated port will be
             printed to the standard output.

     -L [bind_address:]port:host:hostport
     -L [bind_address:]port:remote_socket
     -L local_socket:host:hostport
     -L local_socket:remote_socket
             Specifies that connections to the given TCP port or Unix socket
             on the local (client) host are to be forwarded to the given host
             and port, or Unix socket, on the remote side.  This works by
             allocating a socket to listen to either a TCP port on the local
             side, optionally bound to the specified bind_address, or to a
             Unix socket.  Whenever a connection is made to the local port or
             socket, the connection is forwarded over the secure channel, and
             a connection is made to either host port hostport, or the Unix
             socket remote_socket, from the remote machine.

             Port forwardings can also be specified in the configuration file.
             Only the superuser can forward privileged ports.  IPv6 addresses
             can be specified by enclosing the address in square brackets.

             By default, the local port is bound in accordance with the
             GatewayPorts setting.  However, an explicit bind_address may be
             used to bind the connection to a specific address.  The
             bind_address of “localhost” indicates that the listening port be
             bound for local use only, while an empty address or ‘*’ indicates
             that the port should be available from all interfaces.

````

So you can SSH in from A to B, but send messages back from B to A. And you can restrict the resulting login to use only certain ports, and not support running commands. 

https://mosh.org/ Uses a system like that to connect. 

This works over UDP, so it may not always work. Although, SSH generally works, so the cases where it fails are probably quite rare. 

And it still needs a server, because the connection must be initiated from the clients in all cases. And the server must be raw metal. And the server firewall must allow incoming UDP.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 22:57](https://github.com/HaddingtonDynamics/Dexter/issues/31#issuecomment-722019438):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/31)


-------------------------------------------------------------------------------

# [\#30 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/30) `open`: V2 Tool Interface
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-31 23:36](https://github.com/HaddingtonDynamics/Dexter/issues/30):

A new tool interface with a small TFT screen for user interface, 6th and 7th axis servos and an auto change mechanism for end effectors is being developed. 

Details can be found in the wiki on the [End effectors in general and the future plans](../wiki/End-Effectors) , for the [UI screen](../wiki/End-Effector-Screen), and for the [servoes](../wiki/End-Effector-Servos) used for the additoinal axis.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-18 00:05](https://github.com/HaddingtonDynamics/Dexter/issues/30#issuecomment-422210095):

Duplicate of #24

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 22:53](https://github.com/HaddingtonDynamics/Dexter/issues/30#issuecomment-722018254):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/30)


-------------------------------------------------------------------------------

# [\#29 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/29) `closed`: Gateware screenshots
**Labels**: `Documentation`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 06:11](https://github.com/HaddingtonDynamics/Dexter/issues/29):

Post ScreenShots of Dexter Gateware from Viva for prior, current, and future versions. This will help us be more open source (because we can't release Viva) and will help the rest of the team understand what is going on in the FPGA. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-05-22 18:59](https://github.com/HaddingtonDynamics/Dexter/issues/29#issuecomment-494924764):

Done here:
https://user-images.githubusercontent.com/419392/57746151-be2ea780-7684-11e9-80b5-95490f015973.png

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 22:11](https://github.com/HaddingtonDynamics/Dexter/issues/29#issuecomment-722002595):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/29)


-------------------------------------------------------------------------------

# [\#28 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/28) `open`: Smooth accel with straight and spline
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 06:08](https://github.com/HaddingtonDynamics/Dexter/issues/28):

Accelerate smoothly (constant Jerk) when making straight and spline moves. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 22:10](https://github.com/HaddingtonDynamics/Dexter/issues/28#issuecomment-722002318):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/28)


-------------------------------------------------------------------------------

# [\#27 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/27) `closed`: Fix "freakout" / tourettes when joint goes past limit 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 06:07](https://github.com/HaddingtonDynamics/Dexter/issues/27):

Refuse commands to go past limits? Or allow graceful recovery?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-19 17:16](https://github.com/HaddingtonDynamics/Dexter/issues/27#issuecomment-465225681):

This is fixed on the SpeedsUpdate branch.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 21:59](https://github.com/HaddingtonDynamics/Dexter/issues/27#issuecomment-721997755):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/27)


-------------------------------------------------------------------------------

# [\#26 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/26) `open`: Hardware E-stop 
**Labels**: `Hardware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 06:06](https://github.com/HaddingtonDynamics/Dexter/issues/26):

Hardware E-stop: Power cables come from each robot to the estop switch box. A single, larger, power brick plugs into the switch box to provide power to all the Dexters. It might be worth having a network hub included so all cables run from the same point and only one network connection is required for up to 4 robots. This will allow very rapid physical emergency shutdown of all robots and will simplify connections.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-16 19:15](https://github.com/HaddingtonDynamics/Dexter/issues/26#issuecomment-599714671):

Note that this is not the same as a software e-stop #10

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-10-20 21:23](https://github.com/HaddingtonDynamics/Dexter/issues/26#issuecomment-713147859):

A power cut e-stop will not work in cases where the robot is carrying a load which is delicate or dangerous as that will cause the load to be dropped. An external input into the FPGA which triggers an all stop and hold maybe needed as software e-stop can not be trusted in all cases. If no pin is available on the motor board, perhaps the PMOD connectors on the FPGA board can be used.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 21:50](https://github.com/HaddingtonDynamics/Dexter/issues/26#issuecomment-721993910):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/26)


-------------------------------------------------------------------------------

# [\#25 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/25) `closed`: Upgrade Ubuntu Kernel from 12 to 16 LTS
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 06:01](https://github.com/HaddingtonDynamics/Dexter/issues/25):

Upgrade Ubuntu Kernel from 12 to 16 LTS and produce a new [SD card image](../wiki/SD-Card-Image) for user update. This may allow WiFi support and will allow a more modern version of Node.JS to be installed for local scripting. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-10 23:36](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-420095556):

http://xillybus.com/xillinux
has the new image. I set up an SD card following the directions from:
http://xillybus.com/downloads/doc/xillybus_getting_started_zynq.pdf

I copied the devicetree.dtb file from the FAT partition on our image. And the FPGA xillydemo.bit file. 

With that .dtb file from the old image, the new image will NOT boot; it kernel panics. With the .dtb file provided with the new image, it does boot, but there is only a /dev/uio0 and the extra /dev/uio1 which was on the old image is missing. [DexRun.C expects /dev/uio1](https://github.com/HaddingtonDynamics/Dexter/search?q=%2Fdev%2Fuio1&unscoped_q=%2Fdev%2Fuio1) Modifying DexRun.c to point to the /dev/uio0 causes the ethernet adapter to stop working, and DexRun fails at the test for [`mapped[SENT_BASE_POSITION]!=0` ](https://github.com/HaddingtonDynamics/Dexter/search?q=mapped%5BSENT_BASE_POSITION%5D%21%3D0&unscoped_q=mapped%5BSENT_BASE_POSITION%5D%21%3D0)

I've verified that the correct .bit file is on the image; the `#define INPUT_OFFSET 14` one from https://github.com/HaddingtonDynamics/Dexter/commit/50257ea7178e0d76e99f8571c61051b56fff7421 and that DexRun.c does have that offset.

According to this document;
http://xillybus.com/doc/old-xillinux-zedboard
"boot.bin and xillydemo.bit from Xillinux-1.3 can be used with Xillinux-2.0 with no changes."

Perhaps the device tree was edited to add that new uio1. There is no devicetree.dts file on the old image. The source dts file should be:
https://github.com/xillybus/xillinux-kernel/blob/master/arch/arm/boot/dts/xillinux-microzed.dts

Things that do work:
- It boots!
- DHCP networking. Before release, we need to remember to change it to a fixed IP address. Or I can revisit issue #37 . 
- Password changed to klg as usual so SSH works e.g. PuTTY
- File transfer via SFTP (which uses SSH and has nothing to do with FTP)
- Node.JS v11.6 installed without issue. 

Things that are missing / not configured / not working:
- Samba. Not sure that is worth installing since so many people can't access it. sftp works and is not horrible to use. When DexRun is working, we can use read_from_robot and write_to_robot to transfer files.
- xwindows. I'm trying to figure out if it wasn't installed or what. xstart is on there but fails because there are no displays (normal) so some part of the xwindows system is on it. I can run the editor (leafpad) but I can't run the file manager (nautilus) and gnome-session sits there for a while, then dies, no error messages (may be a log file somewhere). But if I apt-get install gnome-session it says there are about 800MB to download.

Those issues are moot until we can figure out why DexRun.c isn't seeing what it expects in the mapped area.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-08 01:48](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-452145904):

The gcc compiler included in Xillinux 16.04 is C99 standard and `gets(char*)` has been removed from the stdio.h header. Instead, use `fgets(char*, int, FILE)` e.g. `fgets(iString, sizeof(iString), stdio)`

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-16 07:32](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-454680123):

Learning to compile the devicetree so that it can be edited and then re-compiled. 
Following:
http://xillybus.com/downloads/doc/xillybus_getting_started_zynq.pdf
chapter 6, I was able to get the files:
`git clone https://github.com/xillybus/xillinux-kernel.git`
into a folder. But the command
`export CROSS_COMPILE=/path/to/crosscompiler/arm-xilinx-linux-gnueabi`
needs a valid path, and I'll be darned if I can find it. 

Following:
http://xillybus.com/downloads/doc/xillybus_getting_started_linux.pdf
The line:
`apt-get install gcc make kernel-devel-$(uname -r)`
causes an error: "E: You must put some 'source' URIs in your sources.list"
https://techoverflow.net/2018/05/03/how-to-fix-apt-get-source-you-must-put-some-source-uris-in-your-sources-list/
Had the solution.

It appeared to complete once, but now I get `Unable to locate package kernel-devel-4.8.0-36-generic`

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-17 00:28](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-454996096):

http://xillybus.com/pcie-download
says that the "driver" should be included with current Ubuntu distributions (14 or higher, I'm running 16 on my PC and 16 on Dexter). But I've downloaded the files anyway to look at the sample code. As far as I can tell, all of that is designed for use on a PC which has an FPGA in it via the PCIe slot. E.g. NOT for use on the microzed. I think 
http://xillybus.com/downloads/doc/xillybus_getting_started_linux.pdf
is specific to that setup. I'm going back to trying to find the path for the cross compiler in 
http://xillybus.com/downloads/doc/xillybus_getting_started_zynq.pdf

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-18 00:53](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-455387552):

Apparently none of that is actually needed. There is a specific application to compile or decompile device tree files
http://xillybus.com/tutorials/device-tree-zynq-1

I have decompiled our version of the devicetree file from the old v12 OS (see attached)
[devicetree.dts.zip](https://github.com/HaddingtonDynamics/Dexter/files/2771122/devicetree.dts.zip)

In comparison to the new .dts file, I don't see anything that is in our old file that is not in the new file. There are a large number of differences because the format of a decompiled file is slightly different, but even when compiling and decompiling the v16 file, it seems like the v16 file has new items and is not missing anything that is in our v12 file. 

A better comparison is between their original v12 file (decompiled) and our modified V12 file (decompiled), but I'm having a difficult time finding that file in their repo. The only commit is apparently the original, or at least it says it's for Xillinux 1.3 as well as 2.0
https://github.com/xillybus/xillinux-kernel/commits/master/arch/arm/boot/dts/xillinux-microzed.dts
It looks like I can download the original 1.3 image from:
http://xillybus.com/doc/old-xillinux-zedboard

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-18 20:17](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-455674542):

I've downloaded the Xillinux 1.3 image, extracted the .dts file from the boot folder, compiled it, decompiled it (so that the syntax matches as much as possible) and this compared it with the decompiled version of our v12 devicetree.dtb. Here is that session (note all the warnings... no idea what's up with that).

````
~/Documents/xillinux/dtc$ ls *.dts
devicetree.dts  xillinux-1.3-microzed.dts  xillinux-2.0-microzed.dts

~/Documents/xillinux/dtc$ ./dtc -I dts -O dtb -o xillinux-1.3-microzed.dtb xillinux-1.3-microzed.dts 
xillinux-1.3-microzed.dts:47.6-53.5: Warning (unit_address_vs_reg): /pmu: node has a reg or ranges property, but no unit name
xillinux-1.3-microzed.dts:58.33-317.5: Warning (unit_address_vs_reg): /amba@0: node has a unit name, but no reg property
xillinux-1.3-microzed.dts:292.8-300.5: Warning (simple_bus_reg): /amba@0/leds: missing or empty reg/ranges property
xillinux-1.3-microzed.dts:147.33-188.6: Warning (spi_bus_bridge): /amba@0/ps7-qspi@e000d000: node name for SPI buses should be 'spi'
xillinux-1.3-microzed.dtb: Warning (spi_bus_reg): Failed prerequisite 'spi_bus_bridge'
xillinux-1.3-microzed.dts:90.41-114.6: Warning (avoid_unnecessary_addr_size): /amba@0/ps7-ethernet@e000b000: unnecessary #address-cells/#size-cells without "ranges" or child "reg" property
xillinux-1.3-microzed.dts:234.11-253.7: Warning (avoid_unnecessary_addr_size): /amba@0/ps7-slcr@f8000000/clocks: unnecessary #address-cells/#size-cells without "ranges" or child "reg" property
xillinux-1.3-microzed.dts:54.22-57.5: Warning (unique_unit_address): /memory@0: duplicate unit-address (also used in node /amba@0)
xillinux-1.3-microzed.dts:14.3-49: Warning (chosen_node_stdout_path): /chosen:linux,stdout-path: Use 'stdout-path' instead

~/Documents/xillinux/dtc$ ./dtc -I dtb -O dts -o xillinux-1.3-microzed.dts xillinux-1.3-microzed.dtb 
xillinux-1.3-microzed.dts: Warning (unit_address_vs_reg): /pmu: node has a reg or ranges property, but no unit name
xillinux-1.3-microzed.dts: Warning (unit_address_vs_reg): /amba@0: node has a unit name, but no reg property
xillinux-1.3-microzed.dts: Warning (simple_bus_reg): /amba@0/leds: missing or empty reg/ranges property
xillinux-1.3-microzed.dts: Warning (spi_bus_bridge): /amba@0/ps7-qspi@e000d000: node name for SPI buses should be 'spi'
xillinux-1.3-microzed.dts: Warning (spi_bus_reg): Failed prerequisite 'spi_bus_bridge'
xillinux-1.3-microzed.dts: Warning (avoid_unnecessary_addr_size): /amba@0/ps7-ethernet@e000b000: unnecessary #address-cells/#size-cells without "ranges" or child "reg" property
xillinux-1.3-microzed.dts: Warning (avoid_unnecessary_addr_size): /amba@0/ps7-slcr@f8000000/clocks: unnecessary #address-cells/#size-cells without "ranges" or child "reg" property
xillinux-1.3-microzed.dts: Warning (unique_unit_address): /memory@0: duplicate unit-address (also used in node /amba@0)
xillinux-1.3-microzed.dts: Warning (chosen_node_stdout_path): /chosen:linux,stdout-path: Use 'stdout-path' instead

\~/Documents/xillinux/dtc$ diff devicetree.dts xillinux-1.3-microzed.dts
16c16
< 		bootargs = "console=ttyPS0,115200n8 consoleblank=0 root=/dev/mmcblk0p2 rw rootwait earlyprintk mem=0x3f000000";
---
> 		bootargs = "console=ttyPS0,115200n8 consoleblank=0 root=/dev/mmcblk0p2 rw rootwait earlyprintk";
71d70
< 		linux,phandle = <0x01>;
126d124
< 					linux,phandle = <0x04>;
143d140
< 			linux,phandle = <0x05>;
234d230
< 			linux,phandle = <0x02>;
281d276
< 					linux,phandle = <0x03>;
349,355d343
< 			interrupt-parent = <0x02>;
< 		};
< 
< 		xillybus_lite@75c00000 {
< 			compatible = "xillybus,xillybus_lite_of-1.00.a";
< 			reg = <0x75c00000 0x1000>;
< 			interrupts = <0x00 0x3c 0x01>;
````

To summarize the changes: 
- Anytime there is a `phandle = ` a line is added above with `linux,phandle = ` followed by the same value. E.g. `phandle = <0x01>;` is replaced with:
````
		linux,phandle = <0x01>;
		phandle = <0x01>;
````
- ` mem=0x3f000000` has been added to the end of the bootargs line.
- At the end of the file, a new section has been added:
````
		xillybus_lite@75c00000 {
			compatible = "xillybus,xillybus_lite_of-1.00.a";
			reg = <0x75c00000 0x1000>;
			interrupts = <0x00 0x3c 0x01>;
			interrupt-parent = <0x02>;
		};
````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-19 06:58](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-455755655):

So it turns out there is a dtc program on the image at:
/usr/src/kernels/3.12.0-xillinux-1.3/scripts/dtc
and the files compile / decompile without warning when you use it. The result appears to be the same; the same differences are found.

So now to apply the changes to the new dts file. The last section in the source file from the [Xillinux 2.0 repo](https://github.com/xillybus/xillinux-kernel/blob/master/arch/arm/boot/dts/xillinux-microzed.dts) is 
````
		watchdog0: watchdog@f8005000 {
			clocks = <&clkc 45>;
			compatible = "cdns,wdt-r1p2";
			interrupt-parent = <&ps7_scugic_0>;
			interrupts = <0 9 1>;
			reg = <0xf8005000 0x1000>;
			timeout-sec = <10>;
		};
````
And from the decompiled .dtb file it appears as:
````
		watchdog@f8005000 {
			clocks = <0x03 0x2d>;
			compatible = "cdns,wdt-r1p2";
			interrupt-parent = <0x02>;
			interrupts = <0x00 0x09 0x01>;
			reg = <0xf8005000 0x1000>;
			timeout-sec = <0x0a>;
		};
````
So I'm guessing our added section can be 
````
		xillybus_lite@75c00000 {
			compatible = "xillybus,xillybus_lite_of-1.00.a";
			reg = <0x75c00000 0x1000>;
			interrupts = <0 60 1>;
			interrupt-parent = <&ps7_scugic_0>;
		};
````
0x3C is 60 in decimal which appears to be the preferred radix for expressing `interrupts`, and &ps7_scugic_0 appears to translate in to 0x02 as an `interrupt-parent`

I have no idea what to do about the `phandle` as they don't appear in the source file, and only show up in the decompiled versions. I'm going to guess they aren't needed.

The `mem=0x3f000000` has been added to the end of the bootargs line.

With those changes, the new file appears to compile on the old image. Next to place it on the new image, compile there, and see if a /dev/uoi1 shows up.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-20 06:42](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-455842055):

And Dexter is up! DexRun runs, and doesn't crash, DDE connects, move all joints works. 

The source file, made as indicated [above](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-455674542), is attached as
[xillinux-2.0-microzed-dex.dts.zip](https://github.com/HaddingtonDynamics/Dexter/files/2776296/xillinux-2.0-microzed-dex.dts.zip). It gets compiled via the Linux kernel [device tree compiler](https://git.kernel.org/pub/scm/utils/dtc/dtc.git). (must be done on a Linux machine, e.g. on Dexter Ubuntu 16.04)
````
$ git clone git://git.kernel.org/pub/scm/utils/dtc/dtc.git dtc
$ cd dtc
$ make
$ cd ..
$ dtc/dtc -I dts -O dtb -o devicetree.dtb xillinux-2.0-microzed-dex.dts 
````
Which then generates [devicetree.dtb.zip](https://github.com/HaddingtonDynamics/Dexter/files/2776294/devicetree.dtb.zip) which then gets moved to the SDcard FAT partition, and restart
````
$ mount /dev/mmcblk0p1 /mnt/usbstick/
$ mv devicetree.dtb /mnt/usbstick
$ shutdown -restart now
````

I was also able to install samba and get it working by following this tutorial:
https://tutorials.ubuntu.com/tutorial/install-and-configure-samba#0
The username is root and password is klg.

TODO:
- Get the gnome-desktop working. 
- Make DexRun start on boot

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-21 21:37](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-456205083):

Making DexRun run on startup was confusing. The file /etc/rc.local appears to say that each time a user logs in it will execute, but it appears that it is only run once on system startup. So I just added the line:
````
/srv/samba/share/DexRun 1 3 0 &
````
just before the `exit 0` line. I tested by logging in twice and `pgrep DexRun` shows only one copy running. 

P.S. Should we make DexRun check for other DexRuns and not start if one is already running? Or kill the running one and start?

EDIT: That does NOT work. Starting from root, if you do `/srv/samba/share/DexRun 1 3 0 &` it starts, displays all the expected messages, responds to commands, but the arm doesn't move! On the exact same robot, DDE, etc.. if I cd to /srv/samba/share and enter `./DexRun 1 3 0 &` then it DOES work! The issue appears to be the working directory, because if you are in /srv/samba/share, then  `/srv/samba/share/DexRun 1 3 0 &` does work and the arm moves. So the working directory is critical. 

I created a file in /srv/samba/share called RunDexRun and in it put:
````
cd /srv/samba/share
./DexRun 1 3 0 &
````
then changed it's permissions so everyone can run it, and that works from the root directory, e.g. from / the command /srv/samba/share/RunDexRun works. 

So I've edited  /etc/rc.local to put in 
````
/srv/samba/share/RunDexRun
````
and after a restart, Dexter moves again.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-22 07:34](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-456298677):

Had already 
`apt-get install gnome-session`
but
`gnome-session --debug` reports that hardware acceleration failed.
`gnome-session --debug --disable-acceleration-check` fails to find any gnome sessions

`nano /etc/ssh/ssh_config` and changed X11Forwarding yes then `service sshd reload` but I don't think that applies because e.g.
`xclock` or `leafpad` work just fine already.

`apt-get install ubuntu-desktop` but I think that just gets all the apps that can run on the desktop. e.g. libreoffice, etc... Maybe it will also install valid sessions? Yep... Now
`gnome-session --disable-acceleration-check` appears to work, but XMing crashed. Try more tomorrow.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-24 20:50](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-457351275):

`gnome-session --disable-acceleration-check` works, but all you get is a desktop with terminal. No launcher, the right click options just offer to create a folder, open terminal, sort the desktop icons by name, and "Keep Alighted" which is checked. There is no status bar at the top, etc... The debug output is massive: [DexterGnomeSession.log](https://github.com/HaddingtonDynamics/Dexter/files/2793552/DexterGnomeSession.log)

A 2D gnome-session file is apparently needed?

Following this page:
https://askubuntu.com/questions/795301/gnome-classic-on-ubuntu-16-04
I installed the "flashback" to put gnome on 16.04
`sudo apt-get install gnome-session-flashback`

None of that seems to work. Many errors are listed on the debug output. I think the issue is the session files aren't right or I'm not starting it right. Searching for gnome-session documentation, I found this:
https://help.gnome.org/admin/system-admin-guide/stable/session-user.html.en
and realized perhaps its the desktop that isn't being started. Looking in 
`/usr/share/xsessions`
I see a ubuntu.desktop file which contains the same 
`gnome-session --session=ubuntu` which doesn't work. The Lubuntu.desktop file contains:
`/usr/bin/lxsession -s Lubuntu -e LXDE`
which actually works! But it's a very different desktop. Actually a bit more like Windows, with a start menu lower left, and task bar across the bottom.
`/usr/bin/startlxde` also works, but it basically the same with a different wallpaper.

`/usr/bin/openbox-session` Sort of works, but is apparently missing "debian-menu.xml" files so it comes up with a blank grey screen. Right click to access a setup menu. The missing bits can perhaps be downloaded?

Apparently the issue is that 1. we don't have hardware acceleration since there isn't a real graphics card and 2. ubuntu-2d support has been removed, and the standard one expects unity 3d support? Perhaps sticking with Lubuntu desktop is best?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-26 01:26](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-457788155):

DDE is running on the 16.04 image! The following instructions from Bret with one small change to the last line did it:
````
$ git clone https://github.com/cfry/dde
$ cd dde
$ npm i
$ npm run start
````
`npm run build` can't work because the[ electron-packager can't run on arm processors](https://www.npmjs.com/package/electron-packager), although it can apparently create packages for arm7l when run on x86, etc... In this case, we don't need to make a distributable package, we just want to run it. 

A "dde_apps" folder must be created under the "/root" folder (alongside Documents, not in it). 

Setting the dexter0 ip address to `localhost` in the dde_init.js file allows local connection of DDE to DexRun. The program takes a while to load (need faster SD Card and interface?) but operation isn't horribly slow on the Lubuntu desktop.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-26 01:33](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-457788807):

DexRun was crashing whenever I tried to make the robot move. It turns out this was as the result of a "write past end of array" error that has been in the code for a long time. See source code below. In the past, whatever was in memory after RxBuf (usually TxPacket so no harm done) was getting clobbered and there was no indication of it. The new gcc includes code that catches this at run time and causes a `*** stack smashing detected ***` crash.

Here is the relevant code:
https://github.com/HaddingtonDynamics/Dexter/commit/42df0e01285ef8b67764ed53f3cc697df44d4d93#diff-691272021fae98368efb598f8e089c16R1339
````
void UnloadUART(unsigned char* RxBuffer,int length)
{
	int i;
	unsigned char RecData;
	for(i = 0;i < length + 11; i++)
	{
		mapped[UART1_XMIT_CNT] = 16; // generate next data pull
		RecData = mapped[UART_DATA_IN];
		RxBuffer[i] = RecData;
		#ifdef DEBUG_XL320_UART
		printf(" %x ", RecData);
		#endif
		mapped[UART1_XMIT_CNT] = 0; // generate next data pull		 
   	}
}
void SendGoalSetPacket(int newPos, unsigned char servo)
{
 	int i;
  	unsigned char RxBuf[20];
  	unsigned char TxPacket[] =  {0xff, 0xff, 0xfd, 0x00, servo, 0x07, 0x00, 0x03, 30, 0, newPos & 0x00ff, (newPos >> 8) & 0x00ff, 0, 0};
  	unsigned short crcVal;
  	crcVal = update_crc(0, TxPacket, 12);
  	TxPacket[12]=crcVal & 0x00ff;
  	TxPacket[13]=(crcVal >> 8) & 0x00ff;


	SendPacket(TxPacket, 14, CalcUartTimeout(14 + 14),RxBuf, 16);  // send time plus receive time in bytes transacted
  	//UnloadUART(RxBuf,16); // TODO refine actual size
}
````
SendPacket just passes that RxBuf pointer and the 16 onto UnloadUART which then shoves 27 (16+11) bytes into it, writing 7 bytes past its end. [I've updated the code on the SpeedsUpdate branch](https://github.com/HaddingtonDynamics/Dexter/commit/769d4dc53fa3eded806d40d2389f94b8e83700c9) to use sizeof in all cases and set the size of the char array to the size I think it's actually pulling.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-01-26 01:55](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-457790806):

You're reminding me why I don't miss writing C code.
Great detective work!

On Fri, Jan 25, 2019 at 8:33 PM JamesNewton <notifications@github.com>
wrote:

> DexRun was crashing whenever I tried to make the robot move. It turns out
> this was as the result of a "write past end of array" error that has been
> in the code for a long time. See source code below. In the past, whatever
> was in memory after RxBuf (usually TxPacket so no harm done) was getting
> clobbered and there was no indication of it. The new gcc includes code that
> catches this at run time and causes a *** stack smashing detected ***
> crash.
>
> Here is the relevant code:
> 42df0e0#diff-691272021fae98368efb598f8e089c16R1339
> <https://github.com/HaddingtonDynamics/Dexter/commit/42df0e01285ef8b67764ed53f3cc697df44d4d93#diff-691272021fae98368efb598f8e089c16R1339>
>
> void UnloadUART(unsigned char* RxBuffer,int length)
> {
> 	int i;
> 	unsigned char RecData;
> 	for(i = 0;i < length + 11; i++)
> 	{
> 		mapped[UART1_XMIT_CNT] = 16; // generate next data pull
> 		RecData = mapped[UART_DATA_IN];
> 		RxBuffer[i] = RecData;
> 		#ifdef DEBUG_XL320_UART
> 		printf(" %x ", RecData);
> 		#endif
> 		mapped[UART1_XMIT_CNT] = 0; // generate next data pull		
>    	}
> }
> void SendGoalSetPacket(int newPos, unsigned char servo)
> {
>  	int i;
>   	unsigned char RxBuf[20];
>   	unsigned char TxPacket[] =  {0xff, 0xff, 0xfd, 0x00, servo, 0x07, 0x00, 0x03, 30, 0, newPos & 0x00ff, (newPos >> 8) & 0x00ff, 0, 0};
>   	unsigned short crcVal;
>   	crcVal = update_crc(0, TxPacket, 12);
>   	TxPacket[12]=crcVal & 0x00ff;
>   	TxPacket[13]=(crcVal >> 8) & 0x00ff;
>
>
> 	SendPacket(TxPacket, 14, CalcUartTimeout(14 + 14),RxBuf, 16);  // send time plus receive time in bytes transacted
>   	//UnloadUART(RxBuf,16); // TODO refine actual size
> }
>
> SendPacket just passes that RxBuf pointer and the 16 onto UnloadUART which
> then shoves 27 (16+11) bytes into it, writing 7 bytes past its end. I've
> updated the code on the SpeedsUpdate branch
> <https://github.com/HaddingtonDynamics/Dexter/commit/769d4dc53fa3eded806d40d2389f94b8e83700c9>
> to use sizeof in all cases and set the size of the char array to the size I
> think it's actually pulling.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-457788807>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITfXI5HnnNMUMYFqKX6z8VVbY1rNMeks5vG7B9gaJpZM4Vk673>
> .
>

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-01-26 02:10](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-457791842):

From James N above:
"A "dde_apps" folder must be created under the "/root" folder (alongside
Documents, not in it)."

I'm surprised by this because I've seen a "Documents" dir in Linux systems
that SEEMS to
be the same kind of dir that both Windows and MacOS has.
(which itself is a miracle that the 3 agreed on something so sensible.)
Now the code that determines where the dde_apps folder should live
is in DDE main.js,

let documents_dir = app.getPath("documents")
console.log("First try getting 'documents' yielded: " + documents_dir)
let the_dde_apps_dir = documents_dir + "/dde_apps"

So I guess what's happening is that in Linux,

app.getPath("documents") doesn't return

a "Documents" dir at all, but "/root"

This is more expected, ie whenever a decent standard is proposed,

somebody will screw it up.

Now is this the same for Ubuntu running on your laptop,

or can the dde_apps dir be under "documents" there?

BTW, I'm impressed that you figured this out.

Did my console.log statement above help?

I left it in there for just such a possibility.


On Fri, Jan 25, 2019 at 8:33 PM JamesNewton <notifications@github.com>
wrote:

> DexRun was crashing whenever I tried to make the robot move. It turns out
> this was as the result of a "write past end of array" error that has been
> in the code for a long time. See source code below. In the past, whatever
> was in memory after RxBuf (usually TxPacket so no harm done) was getting
> clobbered and there was no indication of it. The new gcc includes code that
> catches this at run time and causes a *** stack smashing detected ***
> crash.
>
> Here is the relevant code:
> 42df0e0#diff-691272021fae98368efb598f8e089c16R1339
> <https://github.com/HaddingtonDynamics/Dexter/commit/42df0e01285ef8b67764ed53f3cc697df44d4d93#diff-691272021fae98368efb598f8e089c16R1339>
>
> void UnloadUART(unsigned char* RxBuffer,int length)
> {
> 	int i;
> 	unsigned char RecData;
> 	for(i = 0;i < length + 11; i++)
> 	{
> 		mapped[UART1_XMIT_CNT] = 16; // generate next data pull
> 		RecData = mapped[UART_DATA_IN];
> 		RxBuffer[i] = RecData;
> 		#ifdef DEBUG_XL320_UART
> 		printf(" %x ", RecData);
> 		#endif
> 		mapped[UART1_XMIT_CNT] = 0; // generate next data pull		
>    	}
> }
> void SendGoalSetPacket(int newPos, unsigned char servo)
> {
>  	int i;
>   	unsigned char RxBuf[20];
>   	unsigned char TxPacket[] =  {0xff, 0xff, 0xfd, 0x00, servo, 0x07, 0x00, 0x03, 30, 0, newPos & 0x00ff, (newPos >> 8) & 0x00ff, 0, 0};
>   	unsigned short crcVal;
>   	crcVal = update_crc(0, TxPacket, 12);
>   	TxPacket[12]=crcVal & 0x00ff;
>   	TxPacket[13]=(crcVal >> 8) & 0x00ff;
>
>
> 	SendPacket(TxPacket, 14, CalcUartTimeout(14 + 14),RxBuf, 16);  // send time plus receive time in bytes transacted
>   	//UnloadUART(RxBuf,16); // TODO refine actual size
> }
>
> SendPacket just passes that RxBuf pointer and the 16 onto UnloadUART which
> then shoves 27 (16+11) bytes into it, writing 7 bytes past its end. I've
> updated the code on the SpeedsUpdate branch
> <https://github.com/HaddingtonDynamics/Dexter/commit/769d4dc53fa3eded806d40d2389f94b8e83700c9>
> to use sizeof in all cases and set the size of the char array to the size I
> think it's actually pulling.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-457788807>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITfXI5HnnNMUMYFqKX6z8VVbY1rNMeks5vG7B9gaJpZM4Vk673>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-26 02:13](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-457792071):

LOL. Adding wifi support required: 1. Plugging in a usb wifi dongle (I didn't even restart... just hot plugged it) 2. configuring my wifi SSID and password. Done. Stable and working nicely so far. I can connect to the robot from DDE on my PC to the adapters IP address and send commands.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-01-29 01:54](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-458376280):

Quick note: On Ubuntu 16.04 PC, you can add the -X to ssh, as in `ssh root@192.168.1.142 -X` and it will forward all XWindows commands back to the local PC. So you can `/usr/bin/startlxde` and the Dexter desktop show up ON the PC desktop! LOL! Luckily, the XDE desktop uses the bottom and left corner, and the Ubuntu desktop uses the top and left side, so they co-exist pretty well. It's fun keeping track of which application is running on which device.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-01 19:52](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-459847020):

I'm setting the cat 5 interface to 192.168.1.142 and using the WiFi interface (via a little USB dongle) via DHCP to my router. The #51 issue is effectively resolved and this greatly simplifies the use of the arm: When no router / wifi is available, a direct connection with CAT5 to a PC provides the expected static IP interface on the 192.168.1 network. With that, the user can SSH in and setup WiFi via the command line or use the xWindows interface to set it up via the very easy configuration dialog box from the network icon in the lower right corner of the desktop. If a fixed IP is desired for the WiFi, that can be configured on Dexter or, if the wifi router is accessible, it might support manually assigned DHCP addresses based on the MAC id of the WiFi adapter. I have NOT been able to get Dexter to drop the DHCP lease, so I would recommend setting that up on the router /before/ enabling WiFi on Dexter.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-03-05 03:23](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-469521462):

Note that for support of the Dynamixel servos, /srv/samba/share/RunDexRun or /etc/rc.local must start DexRun with parameters `1 3 1` vs `1 3 0`. That was an hour and a half of my life and more than a few curse words. I knew that, but had forgotten it. 

I was able to confirm that BOTH servos do work after eventually getting my "3" servo made back into a "1" servo. See the [Wiki Article for programming servos](https://github.com/HaddingtonDynamics/Dexter/wiki/End-Effector-Servos#servo-setup) 

In DDE 2.5.13 LTS, under Jobs / Show robot status, if I press the "run update job" button, at first I get 148.48 and 0 for Joint 6 and Joint 7 "MEASURED ANGLE" but if I first move J6 / J7 by going to Jobs / Run instruction / Show dialog... and enter 0 for J6 and J7 then press "move_all_joints" then go back and do the status thing again, it works correctly. 

Note that the 'a' command values for J6/7 are in servo units, not arcseconds. @JamesWigglesworth says that for J6 zero degrees is actually 512 and for J7 it's 0. 

Apparently, the FPGA needs to be told to move J6/7 before that system becomes active.  As per Kent, we can fire that off automatically on startup. e.g. there is no reason not to. The easiest way to do that is by adding values for J6/7 to a boot dance 'a' command in a make_ins file. This keeps it under customer control. e.g. if they don't want that running, they can delete or modify the file. Figuring out which file to put that in is probably a conversation to have with @JamesWigglesworth , but for now, I've just added `a 0 0 0 0 0 512 0` to the autoexec.make_ins file. 

Sadly, that file /isn't being executed/ because [the code that does it was moved to after the sleep in mode 3!](https://github.com/HaddingtonDynamics/Dexter/commit/c41f0ea6b727788fc68e73a2c01923f54ff180ca#diff-691272021fae98368efb598f8e089c16R5089)

So I'm moving that to the start. 

Now the servos send back position as soon as the robot starts.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-27 21:57](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-525499388):

Note to self: Xillinux 2.0 uses U-BOOT, not GRUB or LILO. 
https://www.denx.de/wiki/view/DULG/Manual

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 21:44](https://github.com/HaddingtonDynamics/Dexter/issues/25#issuecomment-721991445):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/25)


-------------------------------------------------------------------------------

# [\#24 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/24) `open`: New tool interface / end effectors
**Labels**: `Firmware`, `Gateware`, `Hardware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 06:00](https://github.com/HaddingtonDynamics/Dexter/issues/24):

New tool interface / end effectors add Joints 6 and 7 via [Dynamixel XL-320 servos](../wiki/End-Effector-Servos), and provide additional IO and user interface at the tool interface via a [Tinyscreen+](../wiki/End-Effector-Screen). This will support a range of [End Effectors](../wiki/End-Effectors) including a standard gripper as well as others which use the 7th access via a power takeoff, and the IO lines via a set of spring loaded connectors. It should be possible to auto change them. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-18 00:05](https://github.com/HaddingtonDynamics/Dexter/issues/24#issuecomment-422210136):

Duplicate of #30

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 21:42](https://github.com/HaddingtonDynamics/Dexter/issues/24#issuecomment-721990653):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/24)


-------------------------------------------------------------------------------

# [\#23 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/23) `open`: Robot to robot accuracy 
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 05:53](https://github.com/HaddingtonDynamics/Dexter/issues/23):

Record on A, playback on B

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 21:41](https://github.com/HaddingtonDynamics/Dexter/issues/23#issuecomment-721990342):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/23)


-------------------------------------------------------------------------------

# [\#22 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/22) `open`: Golden code disk
**Labels**: `Hardware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 05:53](https://github.com/HaddingtonDynamics/Dexter/issues/22):

Golden code disk is oversized, and so very precise, and is used to calibrate actual disks during mfgr. This will improve the accuracy of the encoders. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-14 00:06](https://github.com/HaddingtonDynamics/Dexter/issues/22#issuecomment-657891556):

Another way of doing this is to use a non-golden physical disk and then compensate for the errors after the fact. Given a way of  measuring the overall actual accuracy, which James W has developed, we need a way of injecting that compensation in to the system. That could be via firmware, gateware, or by editing the himem.dat file. 

```


var result
var J_num = 0
var J_angles = [0, 0, 0, 0, 0]

function example_5_init(){
	let CMD = []
    result = {}
    J_angles = [-180, 0, 0, 0, 0]
    CMD.push(Dexter.move_all_joints(correct_J_angles(J_angles)))
    CMD.push(Dexter.empty_instruction_queue())
    this.user_data.C_state_old = false
    return CMD
}

function example_5_main(){
	return Robot.loop(true, function(){
    	let CMD = []
        
        let rs = this.robot.robot_status
        let measured_angles = [
        	rs[Dexter.J1_MEASURED_ANGLE],
        	rs[Dexter.J2_MEASURED_ANGLE],
        	rs[Dexter.J3_MEASURED_ANGLE],
        	rs[Dexter.J4_MEASURED_ANGLE],
        	rs[Dexter.J5_MEASURED_ANGLE]
        ]
        
        
        
        
        let J2 = measured_angles[J_num]
        let J2_snapped = Math.round(J2/5)*5 + 5
                
        let string = J2_snapped + " : " + Vector.round(J2, 3)
        out(string, "blue", true)
        
    	if(Gamepad.is_key_down("CONTROL") && Gamepad.is_key_down("ALT")){
        	
            let step
            if(Gamepad.is_key_down("SHIFT")){
            	step = 5
            }else if(Gamepad.is_key_down("Z")){
            	step = 0.1
            }else if(Gamepad.is_key_down("X")){
            	step = 0.01
            }else{
            	step = 1
            }
            
            let delta_J_angles = [0, 0, 0, 0, 0]
			if(Gamepad.is_key_down("LEFT")){
            	delta_J_angles[J_num] = step
            }else if(Gamepad.is_key_down("RIGHT")){
            	delta_J_angles[J_num] = -step
            }
            //CMD.push(Dexter.move_all_joints_relative(delta_J_angles))
            
            debugger
            J_angles = Vector.add(J_angles, delta_J_angles)
            CMD.push(Dexter.move_all_joints(correct_J_angles(J_angles)))
            
            if(Gamepad.is_key_down("A")){
            	this.user_data.C_state_old = true
            }else if(this.user_data.C_state_old){
            	speak(string)
                out("Recorded: " + string)
                result["" + J2_snapped] = J2
                this.user_data.C_state_old = false
            }
            
        }else if(Gamepad.is_key_down("ALT") && Gamepad.is_key_down("C")){
        	return Robot.break()
        }
        
        CMD.push(Dexter.empty_instruction_queue())
        return CMD
    })
}

function example_5_final(){
	let CMD = []
    CMD.push(Dexter.move_all_joints([0, 0, 0, 0, 0]))
    return CMD
}



new Job({
	name: "Record_Data",
    keep_history: false,
    show_instructions: false,
    inter_do_item_dur: 0,
    do_list: [
    	example_5_init,
        example_5_main,
        example_5_final
    ]
})

new Brain({name: "b0"})
new Job({
	name: "Save_Data",
    robot: Brain.b0,
    keep_history: false,
    show_instructions: false,
    inter_do_item_dur: 0,
    do_list: [
    	function(){
        	let str = JSON.stringify(sort_and_reformat(result))
            let fp = choose_save_file()
            if(fp){
            	write_file(fp, str)
            }
        }
    ]
})

function correct_J_angles(J_angles){
	let result = JSON.parse(JSON.stringify(J_angles))
	let coeffs = [
    	[0.017772801117188035, -0.16017917223939698],
        [1, 0],
        [1, 0],
        [1, 0],
        [1, 0]
    ]
    
    for(let i = 0; i < coeffs.length; i++){
    	result[i] -= coeffs[i][0] * result[i] + coeffs[i][1]
        //J_angles[i] += (J_angles[i] - coeffs[i][1]) / coeffs[i][0]
    }
    
    return result
}

//correct_J_angles([0, 0, 0, 0, 0])


/*

result

var fp =  choose_file()
var content = file_content(fp)
var result = JSON.parse(content)
//inspect(result)

for(let i = 0; i < result.ideal.length; i++){
	if(9 <= i && i <= 58){
    	result.ideal[i] -= 5
    }else if(59 <= i && i <= 66){
    	result.ideal[i] -= 10
    }else if(67 <= i && i <= 67){
    	result.ideal[i] -= 5
    }else if(68 <= i && i <= 68){
    	result.ideal[i] -= 10
    }
}

var str = JSON.stringify(result)
let fp = choose_save_file()
if(fp){
	write_file(fp, str)
}

var errors = Vector.subtract(result.actual, result.ideal)
var coeffs = Vector.poly_fit(result.ideal, errors)


debugger
my_sort(result)

result.sort(function(a, b){
	debugger
	return parseInt(Object.keys(a)) > parseInt(Object.keys(b))
})


pid_delta = 0.570


*/

function sort_and_reformat(obj){
	let keys = Object.keys(obj)
    let keys_as_nums = []
    for(let i = 0; i < keys.length; i++){
    	keys_as_nums.push(parseInt(keys[i]))
    }
    let keys_as_nums_sorted = keys_as_nums.sort(function(a, b){
    	return a - b	
    })
    
    let result = {
    	ideal: keys_as_nums_sorted,
        actual: []
    }
    
    for(let i = 0; i < keys_as_nums_sorted.length; i++){
        result.actual.push(obj["" + keys_as_nums_sorted[i]])
    }
    
    return result
}


//This is code to sense Keyboard button presses
//It's a patch to impliment a feature that has been introduced in later releases
Gamepad.is_key_down = function(keycode_or_keyname){
    let down_keys = this.down_keys()
    for(let obj of down_keys){
        if(obj.keycode == keycode_or_keyname){
        	return true
        }else if(obj.keyname == keycode_or_keyname){
        	return true
        }
    }
    return false
}

````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 21:40](https://github.com/HaddingtonDynamics/Dexter/issues/22#issuecomment-721989748):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/22)


-------------------------------------------------------------------------------

# [\#21 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/21) `open`: Frequency vs Time follow
**Labels**: `Gateware`, `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 05:51](https://github.com/HaddingtonDynamics/Dexter/issues/21):

Frequency vs Time follow in calibration (take amplitude of eyes out of the equation) for better accuracy from the encoders. Removing the magnitude from the calibration of the eyes. Sort of like Automatic Gain Control AGC for the opto. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 21:39](https://github.com/HaddingtonDynamics/Dexter/issues/21#issuecomment-721989473):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/21)


-------------------------------------------------------------------------------

# [\#20 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/20) `closed`: Spawn bash shell in read_from_robot 
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 05:33](https://github.com/HaddingtonDynamics/Dexter/issues/20):

Extend the [read_from_robot ](../wiki/read-from-robot) command to allow it to spawn a bash shell and inject a command (sent as the pathfile parameter) and return the stdout (and stderr?) text. This would allow greater interaction between the development environment and the operating system on Dexter. For example, DexRun.c could be updated and compiled, then run, by DDE. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-26 05:03](https://github.com/HaddingtonDynamics/Dexter/issues/20#issuecomment-515309964):

http://man7.org/linux/man-pages/man3/system.3.html

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-26 05:08](https://github.com/HaddingtonDynamics/Dexter/issues/20#issuecomment-515310798):

Better, because it acts more like a file:
http://man7.org/linux/man-pages/man3/popen.3.html

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-27 06:37](https://github.com/HaddingtonDynamics/Dexter/issues/20#issuecomment-515657426):

First take on adding the ability to spawn a command to the shell and return the result:

````c
switch(token[0]) { //what's the first character of the path?
case '`': //shell cmd
	printf("shell %s\n", token);
	if(0==i){ //first request
		printf("- popen\n");
		wfp = popen(token, "r"); //to get both stdout and stderr, the command should end with "2>&1"
		if (errno) {
			sendBuffReTyped[5] = errno; //there was an error
			sendBuffReTyped[6] = 0; //no bytes returned
		}
	}
	if(wfp){
		sendBuffReTyped[6] = fread(sendBuff + sizeof(sendBuffReTyped[0])*7, 1, MAX_CONTENT_CHARS, wfp);
		//possible issue: If child process is working to produce more output, you might get less than
		//MAX_CONTENT_CHARS /before/ the child is done. Need to KEEP reading until you get EOF!
		//if(!sendBuffReTyped[6]) {//how do we know the command won't produce more later?
		if(feof(wfp)) { //stream will be set to eof when process is finished
			errno = pclose(wfp); //can this lock up? Shouldn't if the stream is eof
			sendBuffReTyped[5] = errno; //might be zero (no error) or the error returned by the command
		}
	}else { //printf("no wfp");
		sendBuffReTyped[5] = ECHILD; //we are done
		sendBuffReTyped[6] = 0; //no bytes returned
	}
	break;
````

I'm concerned about a case where the shell command is still working to produce output, but doesn't have any to send right now. e.g. we've read all the output and returned 0 characters. Or less than MAX_CONTENT_CHARS characters. So DDE thinks we are done. But the process is NOT finished. We only know the process is finished when we get an EOF on the stream. Then it's safe to call pclose. If we fail to call pclose, the process is still running, the handle is still open and the _next_ time we try to execute a shell command, we crash. I could just call pclose when I'm told to do a new popen and wfp isn't null, but then that will lock DexRun up because pclose doesn't return until the child process is finished, AND... since nothing is reading the stream, it may not finish until the stream buffer is emptied, which creates a circular lock condition. Need to test. May have to change the way read_from_robot is called so that it keeps trying to get data until it gets back the ECHILD error indicating the process terminated.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-30 00:34](https://github.com/HaddingtonDynamics/Dexter/issues/20#issuecomment-516212668):

To avoid this problem, DDE would need to change so that it does NOT stop reading blocks when it gets less than MAX_CONTENT_CHARS returned. Instead, DDE would continue to read even if zero characters  are returned, but would stop reading when an "END_OF_FILE" error is returned. E.g. Some error code that we will decide upon. This will be returned when the process stream has returned EOF, and pclose has been called, so we will need another way to return the error status from the bash command. We can update the standard read_from_robot as used for a file or #file to also return EOF when you try to read past the end of the file, so that DDE can do the same thing in all cases. E.g. We are changing the way that the 'r' oplet reports that it's finished to add an "I'm really, really finished" signal after the "there isn't thing to read" sort of "soft" ending we have now.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-30 05:24](https://github.com/HaddingtonDynamics/Dexter/issues/20#issuecomment-516267228):

Actually, we can just force one more round of reading back data AFTER the EOF which will return ECHILD (or perhaps we should make up another higher error number?) because the file handle will be null. 

We should check for the file handle NOT being null on block zero and return an error so that the host knows a child process is still waiting to be cleared. Maybe EBUSY? Or a higher one we make up.

Here is the current code.

````c
switch(token[0]) { //what's the first character of the path?
case '`': //shell cmd
	printf("shell %s\n", token);
	if(0==i){ //first request
		printf("- popen\n");
		if (wpp) { //we can't start a new one, 'case the old one isn't done.
			sendBuffReTyped[5] = EBUSY; //the system is busy
			sendBuffReTyped[6] = 0; //no bytes returned.
			break; //Host should request block 1 or higher with "`" and toss the data until EOF
		}
		wpp = popen(token, "r"); //to get both stdout and stderr, the command should end with "2>&1"
		if (errno) {
			sendBuffReTyped[5] = errno; //there was an error
			sendBuffReTyped[6] = 0; //no bytes returned
		}
	}
	if(wpp){
		sendBuffReTyped[6] = fread(sendBuff + sizeof(sendBuffReTyped[0])*7, 1, MAX_CONTENT_CHARS, wpp);
		//possible issue: If child process is working to produce more output, you might get less than
		//MAX_CONTENT_CHARS /before/ the child is done. Need to KEEP reading until you get EOF!
		if(feof(wpp)) { //stream will be set to eof when process is finished
			errno = pclose(wpp); //can this lock up? Shouldn't if the stream is eof
			sendBuffReTyped[5] = errno; //might be zero (no error) or the error returned by the command
		}
	}else { //printf("no wpp");
		sendBuffReTyped[5] = ECHILD; //we are done
		sendBuffReTyped[6] = 0; //no bytes returned
	}
	break;
````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-31 06:01](https://github.com/HaddingtonDynamics/Dexter/issues/20#issuecomment-516708597):

Error codes on this are going to be interesting. It turns out I was sending the back tick along with the command to popen. E.g. instead of sending "uname", I was sending "\`uname" and it returned an error code of 512. The printf debug statement said "sh: 1: Syntax error: EOF in backquote substitution". I've NO idea where to find a list of error codes from Linux that goes up to 512. 

Found the pclose does NOT zero out the file handle, so I had to add that myself. 

Current code seems to work. I had to update the node web proxy index.html page to correctly decode 'r' return data and display it, and to console.log error codes so I could debug it as DDE is not currently able to send the commands as needed. I found a short Linux command which returns a short value: `uname` gives back `Linux`. So "r 0 \`uname" returned r 6 Linux and "r 1 \`uname" returned error 10 (ECHILD) as expected. And I was able to repeat that. 

````c
case '`': //shell cmd
	printf("shell %s\n", token);
	if(0==i){ //first request
		printf("- popen\n");
		if (wpp) { //we can't start a new one, 'case the old one isn't done.
			sendBuffReTyped[5] = EBUSY; //the system is busy
			sendBuffReTyped[6] = 0; //no bytes returned.
			break; //Host should request block 1 or higher with "`" and toss the data until EOF
		}
		wpp = popen(token+1, "r"); //to get both stdout and stderr, the command should end with "2>&1"
		if (errno) {
			sendBuffReTyped[5] = errno; //there was an error
			sendBuffReTyped[6] = 0; //no bytes returned
		}
	}
	if(wpp){
		sendBuffReTyped[6] = fread(sendBuff + sizeof(sendBuffReTyped[0])*7, 1, MAX_CONTENT_CHARS, wpp);
		//possible issue: If child process is working to produce more output, you might get less than
		//MAX_CONTENT_CHARS /before/ the child is done. Need to KEEP reading until you get EOF!
		if(feof(wpp)) { //printf("EOF\n");//stream will be set to eof when process is finished
			errno = pclose(wpp); //can this lock up? Shouldn't if the stream is eof
			sendBuffReTyped[5] = errno; //might be zero (no error) or the error returned by the command
			wpp = 0; //must zero out wpp so we know it's closed.
		}
	}else { //printf("no wpp");
		sendBuffReTyped[5] = ECHILD; //we are done
		sendBuffReTyped[6] = 0; //no bytes returned
	}
	break;

````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-08-21 19:09](https://github.com/HaddingtonDynamics/Dexter/issues/20#issuecomment-523607791):

This is completed and working as of 2018/08/16 on the StepAngles branch:
https://github.com/HaddingtonDynamics/Dexter/commit/ce61cf652dc591dab8ba1096834206f7c551ce72
with a bug fix (to allow multi word commands) in
https://github.com/HaddingtonDynamics/Dexter/commit/104df3f9f2897df3c94e655ca17ca8ee68365aea

current code is:
````c
case '`': //shell cmd
	//printf("shell %s\n", token);
	if(0==i){ //first request
		if (wpp) { //we can't start a new one, 'case the old one isn't done.
			sendBuffReTyped[5] = EBUSY; //the system is busy
			sendBuffReTyped[6] = 0; //no bytes returned.
			break; //Host should request block 1 or higher with "`" and toss the data until EOF
		}
		printf("popen %s \n",token+1);
		wpp = popen(token+1, "r"); //to get both stdout and stderr, the command should end with "2>&1"
		if (errno) {
			sendBuffReTyped[5] = errno; //there was an error
			sendBuffReTyped[6] = 0; //no bytes returned
		}
	}
	if(wpp){
		sendBuffReTyped[6] = fread(sendBuff + sizeof(sendBuffReTyped[0])*7, 1, MAX_CONTENT_CHARS, wpp);
		//possible issue: If child process is working to produce more output, you might get less than
		//MAX_CONTENT_CHARS /before/ the child is done. Need to KEEP reading until you get EOF!
		if(feof(wpp)) { //printf("EOF\n");//stream will be set to eof when process is finished
			errno = pclose(wpp); //can this lock up? Shouldn't if the stream is eof
			sendBuffReTyped[5] = errno; //might be zero (no error) or the error returned by the command
			wpp = 0; //must zero out wpp so we know it's closed.
		}
	}else { //printf("no wpp");
		sendBuffReTyped[5] = ECHILD; //we are done
		sendBuffReTyped[6] = 0; //no bytes returned
	}
	break;
````

But notice the change just before this:
````c
		//token=strtok(NULL, delimiters); //this would get only one word, 
		token=strtok(NULL, ";"); // get the entire rest of the string. 
		//";" was already nulled, but it will stop at null
````

We used to strtok just the next word, but this change will cause it to grab the entire remainder of the line. This is necessary to support commands like `ls /root/Documents` where there are two or more "words" and it doesn't stop at the first space. 

This, then, requires the following changes to the code for "#" keywords and actual files:
````c
token = strtok(token, delimiters); //now get just the first word.
````
where we re-strtok the token pointer to get just the first word of the line. If we don't do this, commands like `r 0 #Steps ;` will fail because "#Steps " does not match "#Steps" and we can't be certain the user will NOT send that extra space at the end. Also for file names, Linux does not trim trailing spaces. It is entirely possible (though unlikely and evil) to have a file called "try-to-delete-me " which you can NOT delete without enclosing the name in quotes. e.g. `rm try-to-delete-me` will fail because it's missing the trailing space. Sadly, our current (and former) systems would never be able to read that file because they WILL stop at a space, even one inside quotes. Hopefully that is a non-issue. We could do a "r 0 `cat "try-to-delete-me"" and that should read back the file, assuming it's just standard text.

In any case, this shell ability seems to work and provides us with the ability to read directories, erase files, and cause all sort of mayhem in the onboard file system.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 20:13](https://github.com/HaddingtonDynamics/Dexter/issues/20#issuecomment-721950742):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/20)


-------------------------------------------------------------------------------

# [\#19 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/19) `closed`: Firmware return error for unknown instruction
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 05:20](https://github.com/HaddingtonDynamics/Dexter/issues/19):

In order for DDE to know if an instruction can actually be executed or not, the firmware needs to return an error if the instruction isn't known. At this point, we can test some changes: In the case of [read_from_robot](../wiki/read-from-robot), DDE can tell if the command is not implemented because there will be no file data returned if the firmware hasn't been updated to implement the command. The [write_to_robot](../wiki/write-to-robot) command can be verified via read_from_robot (checking to see if the file was written). However, In the future, other commands may not return data, so an error message is a good idea. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-07-28 05:21](https://github.com/HaddingtonDynamics/Dexter/issues/19#issuecomment-408583855):

@kgallspark Can the the Dynamixel command support be detected by looking for Joint 6 / 7 info in the status data? Does it return extra status data for those joints now?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-07-28 05:24](https://github.com/HaddingtonDynamics/Dexter/issues/19#issuecomment-408583962):

@cfry with the ability to detect if a function isn't supported, either by a lack of return data, or an error message in the future, DDE could suggest user load a new [SD Card image](../wiki/SD-Card-Image) if oplet isn't found

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-08-02 18:29](https://github.com/HaddingtonDynamics/Dexter/issues/19#issuecomment-410024192):

Looks like the [default:](https://github.com/HaddingtonDynamics/Dexter/blob/243ac0fa3c995effd9c75731d3a9c7ecb70cc73e/Firmware/DexRun.c#L3972) just needs to `return false; // (0)` and the return after the switch should return true?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:59](https://github.com/HaddingtonDynamics/Dexter/issues/19#issuecomment-721944273):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/19)


-------------------------------------------------------------------------------

# [\#18 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/18) `closed`: Instruction number in status
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 05:05](https://github.com/HaddingtonDynamics/Dexter/issues/18):

The firmware should return the current (or previous) instruction id number in the status data. This will help coordinate between DDE and Dexter. Scripts need to take actions when the robot has actually completed (or is working on) a previously send instruction.

The only trick is figuring out which item in the status data to replace with the instruction id. Documenting the actual status data #17 will help to pick one to replace. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-07-22 22:00](https://github.com/HaddingtonDynamics/Dexter/issues/18#issuecomment-513971694):

It already does... and always has... at least since we started using github:
https://github.com/HaddingtonDynamics/Dexter/blame/add3e2e36c891be3e4853c9b1daac0d76035f576/Firmware/DexRun.c#L2776

I've just retested and verified via the onboard http proxy server /srv/samba/share/www/. The instruction numbers are absolutely being echoed.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:58](https://github.com/HaddingtonDynamics/Dexter/issues/18#issuecomment-721943942):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/18)


-------------------------------------------------------------------------------

# [\#17 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/17) `closed`: Document status data
**Labels**: `Documentation`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 04:55](https://github.com/HaddingtonDynamics/Dexter/issues/17):

The actual use of each bit of data returned in the status needs to be documented. Understanding that will allow us to use and change that data in more useful ways. A start has been made for [status data in the wiki](../wiki/status-data).

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-02-19 17:17](https://github.com/HaddingtonDynamics/Dexter/issues/17#issuecomment-465226219):

Currently up to date.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:58](https://github.com/HaddingtonDynamics/Dexter/issues/17#issuecomment-721943757):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/17)


-------------------------------------------------------------------------------

# [\#16 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/16) `closed`: Remote operation / monitoring
**Labels**: `enhancement`, `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 01:16](https://github.com/HaddingtonDynamics/Dexter/issues/16):

In cases were Dexters are operating remotely, it will be important to get their status, and perhaps operate them over the internet. We already have a way of converting the actual socket connections used by the firmware into WebSocket connections (which are NOT socket connections at all) via the [node.js server](../wiki/nodejs-webserver)

To move this out to the internet, basically, we need a chat server: Each Dexter nodeJS server will connect to the chat server on startup, be registered as a robot in the "chat" and then when a human connects his or her browser to the chat server, they will see a list of online Dexters, and can send any of them a message. That message would go to the server, which would then relay it to the open websocket connection to that Dexter. The NodeJS server on the Dexter would receive the message, relay it as a true socket message to the firmware on localhost, pick up the response, and relay it back to the chat server via websocket. The chat server would then relay that back to the human via the websocket connection to the browser. Like a Private Message on a standard chat server.

Speed is very important for this application since moving the robot precisely requires very fast feedback.

If you have experience spinning up Node.JS servers on public facing platforms, we'd like to hear from you. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-05 02:10](https://github.com/HaddingtonDynamics/Dexter/issues/16#issuecomment-418576234):

Duplicate of #31

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:57](https://github.com/HaddingtonDynamics/Dexter/issues/16#issuecomment-721943490):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/16)


-------------------------------------------------------------------------------

# [\#15 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/15) `closed`: Exact Link lengths
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 01:08](https://github.com/HaddingtonDynamics/Dexter/issues/15):

Each Dexter robot may have different lengths for each link between joints 2 and 3, and 3 and 4. Different versions and designs for Dexter may have different placements of the joints. Being able to accurately track and understand the joint lengths becomes important when doing precise operations like force sensing. #14 

DDE has had a system in place for changing the default link lengths since [version 2.3.15](https://github.com/cfry/dde/commit/71303d1439ae26cc48d36c452045d0f9cab76927)
but there isn't a way to get that data from the robot automatically. 

Use [read_from_robot](../wiki/read-from-robot) to automatically get a LinkLengths.txt file from the robot (assuming it supports that function)?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-11-21 19:12](https://github.com/HaddingtonDynamics/Dexter/issues/15#issuecomment-440779068):

Completed in 
https://github.com/HaddingtonDynamics/Dexter/commit/f0d9fa772ba6c3eee979e62a071bca487a084c21

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:56](https://github.com/HaddingtonDynamics/Dexter/issues/15#issuecomment-721943044):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/15)


-------------------------------------------------------------------------------

# [\#14 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/14) `open`: Force sensing / weight measurements
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:52](https://github.com/HaddingtonDynamics/Dexter/issues/14):

If we  have a very accurate sense of the center of mass of each link between joints #15 , and know the exact position of each joint #12 then we can compute the force due to gravity that the arm should be subjected to. Given this information, if we can sense torque on each joint #13 , then we can measure any additional weight or force being applied.

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) commented at [2020-08-26 22:16](https://github.com/HaddingtonDynamics/Dexter/issues/14#issuecomment-681152061):

This example shows a method of [measuring torques and forces with Dexter from DDE](https://github.com/HaddingtonDynamics/Dexter/blob/Stable_Conedrive/DDE/examples/TorquesAndForcesExample.dde)
There is error of about a factor of 10 in force sensing measurements done with move_until_force.
The method used to calculate force in move_until_force makes some approximations and assumptions that may be causing this error:
 
-An external force calculation requires external torques. 
 As of now Dexter's joints can only measure total torque which will include the contribution of robot's own weight and accelerations.
 We can make an approximation by "zeroing out" the torques while it's unloaded and before it starts moving.
 This is an approximation because when the robot moves each joint's center of mass will move and contribute to the torque.
 (This is why you will see non-zero and changing values before it touches anything)
 We have just completed characterizing each links center of mass so this addition may be coming soon.
 
-The force calculation assumes a point force applied at the end-effector point.
 If there are multiple points of contact then a torque may be applied at the end-effector and the math will not hold true.
 If the point of contact is in a different position from where the link lengths describe, then the moment arms will be inaccurate.
 The angle of the applied force is very sensitive to moment arm inaccuracies
 
-The external force is assumed to be along the direction of movement.
 The force_threshold is only a measurement of external forces acting along 'force_vector'.
 When 'force_vector' is left as undefined it defaults to the opposite direction of the 'motion_direction'.
 i.e. if you move downward it will only look at the upward forces. 
 If the actual applied force is not in the direction of the 'force_vector' then only a component of it will be used in the comparison.
 This means that 'force_threshold' will not match the actual applied force magnitude if it is at an angle.
 This will be the case if the movement_direction is not perpendicular to the surface it is hitting.
 
-The static calculations assume a rigid non-moving body.
 Deflections about a joint's axis are accounted for but if a link is bending or deflecting out of plane the math will be off.
 If the joint hasn't settled in its movement yet or joint has stopped moving but the motor hasn't there will be error.
 
-The torque measurement assumes that the torque calibration done at one angle holds true for all angles.
 I suspect that because we calibrate the encoder joint angle while under the effects of gravity, the difference between motor angle and encoder angle may already have some torque information biasing it.
This is mostly an unknown just due to a lack of testing time.

See the issue on [torque sensing
](https://github.com/HaddingtonDynamics/Dexter/issues/13#issuecomment-681137100)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:54](https://github.com/HaddingtonDynamics/Dexter/issues/14#issuecomment-721942113):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/14)


-------------------------------------------------------------------------------

# [\#13 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/13) `open`: Torque sensing
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:48](https://github.com/HaddingtonDynamics/Dexter/issues/13):

If we know the stepper angle (meaning the angle the stepper motor has been told to go), as well as the actually measured angle #12 and there is little to no mechanical backlash #7 then we can accurately measure the torque on each joint. This can give Dexter an accurate sense of touch, which allows sensing collisions, the location of the workspace, and other objects.

Even now, we could move to a point, zero out the error, then move to another point, and watch the error until it exceeds a threshold, indicating a contact. If the two points are fairly close together, backlash, changes in gravitational pull and other issues are unlikely to influence the feedback.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-11 00:34](https://github.com/HaddingtonDynamics/Dexter/issues/13#issuecomment-420105963):

The torque on the joint in Newton meters (&Tau;) is the difference between the STEPPER_ANGLE and the MEASURED_ANGLE (&Delta; &theta;), times a "stiffness" constant (k) in Newton meters / degree. 

&Tau; = k &sdot; &Delta;&theta;

The STEPPER_ANGLE corresponds to the Move all Joints command in DDE. Using the BASE (Joint 1) as an example, is BASE_POSITION_AT + BASE_POSITION_PID_DELTA + BASE_POSITION_FORCE_DELTA + PLAYBACK_BASE_POSITION + FINE_ADJUST_BASE. 

FINE_ADJUST_BASE is a value that we set in via [DexRun](https://github.com/HaddingtonDynamics/Dexter/blob/93e0cb36682b3c74bcfe6afa11ad66ffefbbb6e3/Firmware/DexRun.c#L2903)

BASE_MEASURED_ANGLE will be returned in place of PLAYBACK_BASE_POSITION.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-08 19:12](https://github.com/HaddingtonDynamics/Dexter/issues/13#issuecomment-427947880):

It is critical to understand that the output of the PID is NOT a drive "strength" signal as one might have with a PWM output to a DC motor drive or a ESC driving a BLDC motor. The output is some number of step pulses per second telling the stepper motor to move to a new location, which then applies force to correct the error. The "_DELTA" positions are always going to be run all the way to zero if the stepper driver has the strength to do so. There is NO remaining error, unlike what there would be in a more traditional PID servo system using only the P term.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-15 23:35](https://github.com/HaddingtonDynamics/Dexter/issues/13#issuecomment-430050126):

Note: Ensure FPGA address 78 bit0 is ZERO via the [write oplet](https://github.com/HaddingtonDynamics/Dexter/wiki/oplet-write) to allow the PID_DELTA values to change and indicate how much corrective position adjustment is being applied. If we know how much it has corrected to hold position, we can calculate the torque.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-13 17:53](https://github.com/HaddingtonDynamics/Dexter/issues/13#issuecomment-657702539):

The gateware added the ability to read the step angles on the "Step Angle" branch, and that was merged into the the "Stable_Conedrive" branch which will be the next standard. An example job showing how to use this should be added here, and then this issue can be closed as soon as the new branch is in production.

#### <img src="https://avatars3.githubusercontent.com/u/26582517?v=4" width="50">[JamesWigglesworth](https://github.com/JamesWigglesworth) commented at [2020-08-26 21:37](https://github.com/HaddingtonDynamics/Dexter/issues/13#issuecomment-681137100):

This example shows a method of [measuring torques and forces with Dexter from DDE](https://github.com/HaddingtonDynamics/Dexter/blob/Stable_Conedrive/DDE/examples/TorquesAndForcesExample.dde)
The current (8/26/20) method for measuring torques makes a few assumptions and approximations that may cause inaccuracies:

-As of now Dexter's joints can only measure total torque which will include the contribution of robot's own weight and accelerations.
 We can make an approximation by "zeroing out" the torques while it's unloaded and before it starts moving.
 This is an approximation because when the robot moves each joint's center of mass will move and contribute to the torque.
 (This is why you will see non-zero and changing values before it touches anything)
 We have just completed characterizing each links center of mass so this addition may be coming soon.
https://github.com/HaddingtonDynamics/Dexter/wiki/Dynamics#center-of-mass-measurements

-The torque measurement assumes that the torque calibration done at one angle holds true for all angles.
 I suspect that because we calibrate the encoder joint angle while under the effects of gravity, the difference between motor angle and encoder angle may already have some torque information biasing it.
This is mostly an unknown just due to a lack of testing time.


A proposed solution to this would be to calibrate the robot's J2, J3, and J4 encoders with the robot on its side so that these joints are not affected by gravity.
The torque due to gravity can then be calculated from each link's angle and center of mass and removed from the torque measurement.

Right now if J2 was 90 degrees and everything else was at 0 the robot would report 0 torque for J2.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-09-14 23:00](https://github.com/HaddingtonDynamics/Dexter/issues/13#issuecomment-692362689):

Added a new setting for the stiffness of each joint: 
`S JointStiffness <ratio> <joint>;`
Parameters are a ratio (unit-less) and a joint number.

````
		case 59: //JointStiffness
			if (a3 > 0 && a3 <= NUM_JOINTS) {
				a3--; //convert to zero index
				printf("J%d stiffness was %f", a3+1, JointStiff[a3]);
				JointStiff[a3] = fa2;
				printf(" now %f\n", fa2);
				return 0;
				}
			break;
````

Example entry from Defaults.make_ins:

```
; Set joint stiffness ratios for this robot.
S JointStiffness 12.895, 1; Joint 1 stiffness
S JointStiffness 12.895, 2; Joint 2 stiffness
S JointStiffness 1.2568, 3; Joint 3 stiffness
S JointStiffness 0.1503, 4; Joint 4 stiffness
S JointStiffness 0.1503, 5; Joint 5 stiffness
````

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:49](https://github.com/HaddingtonDynamics/Dexter/issues/13#issuecomment-721939620):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/13)


-------------------------------------------------------------------------------

# [\#12 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/12) `closed`: Bring measured angles out of FPGA 
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:38](https://github.com/HaddingtonDynamics/Dexter/issues/12):

Currently only the error between the desired angle and the actual angle is available for read-back from the FPGA. Knowing the actual angle of the joint will simplify adding several functions. 

Read back from Firmware to DDE via #11 ?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-07-30 23:11](https://github.com/HaddingtonDynamics/Dexter/issues/12#issuecomment-409041647):

FPGA coded and compiled, needs to be tested and DexRun.c updated. Need documentation on the addresses in the FPGA that were used from @kgallspark  and also an image to develop against. It would be nice if the NodeJS stuff were in that image so it doesn't have to be re-installed.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-13 17:01](https://github.com/HaddingtonDynamics/Dexter/issues/12#issuecomment-421078777):

Measured angles are being returned in the [standard status oplet 'g'](../wiki/status-data) via this commit on the TDint branch: https://github.com/HaddingtonDynamics/Dexter/commit/1ca9251b47468d9841713ec89b62e91050125188

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:38](https://github.com/HaddingtonDynamics/Dexter/issues/12#issuecomment-721934356):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/12)


-------------------------------------------------------------------------------

# [\#11 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/11) `closed`: Return FPGA data

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:36](https://github.com/HaddingtonDynamics/Dexter/issues/11):

Get XYZ, cosine, other data back from the FPGA through DexRun.c to DDE.

While there may be some room in the return status data, many possible return data items may be of use in the future. Use [read_from_robot](../wiki/read-from-robot) for #XYZ "file"? Or use #FPGA and an address number for general purpose access?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-13 16:58](https://github.com/HaddingtonDynamics/Dexter/issues/11#issuecomment-421078058):

#XYZ was added here: https://github.com/HaddingtonDynamics/Dexter/commit/0a55652894b1e445b9233f22fe0c8e782c6c62a2 but the actual code is here: https://github.com/HaddingtonDynamics/Dexter/commit/e6db50da946176123e191e9af6660a318f240489 starting at line 2118

> Requires  gateware release of 8/26/2018 (no version number yet)
> 
> -New register constants for measured angles
> -New structure called pos_ori_mat (short for "position orientation matrix"):
>     -access each element in the form of A.r0.c0, r is the rows 0-3 and c is the columns 0-3
> -New function J_angles_to_pos_ori_mat():
>     -converts 5 joint angles to a coordinate system of the last joint in the form of a pos_ori_mat
>     -origin is located at point 4 i.e. centered on J5's axis, above the differential at height L5 from the axis of J4.
>     -the orientation aligns with the robot's coordinate system when in home position: Z is aligned with the J5 axis positive upward, Y is 
>       in the direction of the end-effector, and X the cross product of of the Y and Z vectors (in that order, right hand rule)
> -pos_ori_mat_to_string(): takes inputs of a pos_ri_mat and a char array, fills the char array with the matrix string
> -psuedo-file functionality added to read_from_robot
>     -file paths that start with '#' will return file contents for particular data without creating an actual file
>     -#XYZ returns the current measured pos_ori_mat
>     -#measured_angles returns the current measured angles
>     -more functionality on the way

Note that measured angles are also being returned in the [standard status oplet 'g'](../wiki/status-data) via this commit on the TDint branch: https://github.com/HaddingtonDynamics/Dexter/commit/1ca9251b47468d9841713ec89b62e91050125188

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-09-14 16:51](https://github.com/HaddingtonDynamics/Dexter/issues/11#issuecomment-421419046):

| Requires gateware release of 8/26/2018 (no version number yet)
| 
| -New register constants for measured angles
| -New structure called pos_ori_mat (short for "position orientation matrix"):

Check with James W but I think this might be a "pose".

Let's be careful here with terminology, inventing names,

and consistency.

See Doc pane/Articles/Dexter Kinematics/Glossary

This needs work.

| -access each element in the form of A.r0.c0, r is the rows 0-3 and c is the
| columns 0-3
| -New function J_angles_to_pos_ori_mat():
| -converts 5 joint angles to a coordinate system of the last joint in the
| form of a pos_ori_mat
| -origin is located at point 4 i.e. centered on J5's axis, above the
| differential at height L5 from the axis of J4.
| -the orientation aligns with the robot's coordinate system when in home
| position: Z is aligned with the J5 axis positive upward, Y is
| in the direction of the end-effector, and X the cross product of of the Y
| and Z vectors (in that order, right hand rule)
| -pos_ori_mat_to_string(): takes inputs of a pos_ri_mat and a char array,
| fills the char array with the matrix string

by pos_ri_mat did you really mean pos_ori_mat ?

Still need terminology standardization.


| -psuedo-file functionality added to read_from_robot
| -file paths that start with '#' will return file contents for particular
| data without creating an actual file

Did you really mean to say "will return a string even though there's

no actual file associated with the "file name" ?

| -#XYZ returns the current measured pos_ori_mat
| -#measured_angles returns the current measured angles
| -more functionality on the way

It looks like you're using # as a prefix to mean

"this is just pure date, there's no actual file associated with it.

But unix does't need that # ie   /dev/null

so wouldn't it be best to follow the Unix convention here?

We might have some data that we decide to implement as

a standard file, then realize later it needs to be "dynamic".

If we DON'T have the "#" prefix, then we don't have to

change user code referencing it, we're just "swapping" the

underlying representation. What does the user care if

its a file or dynamically created?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-09-14 17:44](https://github.com/HaddingtonDynamics/Dexter/issues/11#issuecomment-421433393):

_prior reponse edited to clarify what was quoted and what was a new comment. email replies don't support markdown (which makes sense, as email is rarely written in markdown) so clarity is better if comments are made on the issue instead of via email._

Since the [read from robot](../wiki/read-from-robot) oplet was written and documented as returning file data, it's later use to return dynamically generated strings was thought of as dynamically generated files. It is, as noted, just returning a string.

The # symbol was chosen specifically because the common file systems (Linux, Mac, ,Windows) do not allow it, and therefore, there is no chance of blocking access to a real file. If we had chosen e.g. _ as our flag that this was a request for a dynamically generated "file" then it would be impossible to access a file named e.g. _test. This ensures that the user will always have access to every file on the file system irrespective of it's name, or what dynamically generated files are supported in the firmware and this new usage of the mechanism to return strings can't possible interfere with it's original function.

Note: The read from robot opet was chosen for this because the string could easily be longer than one socket packet. Strings were desirable because they avoid having to interpret binary data which is a problem for some languages and programmers, myself included.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2018-09-14 17:58](https://github.com/HaddingtonDynamics/Dexter/issues/11#issuecomment-421437451):

Ahh, I see. We can imagine /foo  as a file and /#foo as
extra data. In the unix case, maybe they control carefully
the "dynamic" names so as not to insure conflicts,
ie you can't create a file named /dev/null,
unix would just error if you tried.
But we can't so easily do that.

On Fri, Sep 14, 2018 at 1:44 PM JamesNewton <notifications@github.com>
wrote:

> *prior reponse edited to clarify what was quoted and what was a new
> comment. email replies don't support markdown (which makes sense, as email
> is rarely written in markdown) so clarity is better if comments are made on
> the issue instead of via email.*
>
> Since the read from robot <http://../wiki/read-from-robot> oplet was
> written and documented as returning file data, it's later use to return
> dynamically generated strings was thought of as dynamically generated
> files. It is, as noted, just returning a string.
>
> The # symbol was chosen specifically because the common file systems
> (Linux, Mac, ,Windows) do not allow it, and therefore, there is no chance
> of blocking access to a real file. If we had chosen e.g. _ as our flag that
> this was a request for a dynamically generated "file" then it would be
> impossible to access a file named e.g. _test. This ensures that the user
> will always have access to every file on the file system irrespective of
> it's name, or what dynamically generated files are supported in the
> firmware and this new usage of the mechanism to return strings can't
> possible interfere with it's original function.
>
> Note: The read from robot opet was chosen for this because the string
> could easily be longer than one socket packet. Strings were desirable
> because they avoid having to interpret binary data which is a problem for
> some languages and programmers, myself included.
>
> —
> You are receiving this because you were assigned.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/11#issuecomment-421433393>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/ABITfRqNInhkBrT52AxLCtwq8LablEdUks5ua-rngaJpZM4Vk061>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:37](https://github.com/HaddingtonDynamics/Dexter/issues/11#issuecomment-721933633):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/11)


-------------------------------------------------------------------------------

# [\#10 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/10) `open`: Software e-stop 
**Labels**: `enhancement`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:22](https://github.com/HaddingtonDynamics/Dexter/issues/10):

Clear queue AND stop current movement. Implement in FPGA and DexRun.c as optional extra param to "E" oplet. Maybe just pause? Or totally flush? As different param options? 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-07-30 19:32](https://github.com/HaddingtonDynamics/Dexter/issues/10#issuecomment-408983134):

This is listed on the DDE repo as
https://github.com/cfry/dde/issues/20

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-03-16 19:14](https://github.com/HaddingtonDynamics/Dexter/issues/10#issuecomment-599714409):

Notice that this is NOT the same as the Hardware e-stop #26

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-27 22:56](https://github.com/HaddingtonDynamics/Dexter/issues/10#issuecomment-682231921):

There is a register in the FPGA that seems to mention an estop:

78 | RESET_PID_AND_FLUSH_QUEUE | bit 0 resets PID_DELTA. Bit 1 is E_STOP? Set to all zero for normal operation.
-- | -- | --

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:24](https://github.com/HaddingtonDynamics/Dexter/issues/10#issuecomment-721927143):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/10)


-------------------------------------------------------------------------------

# [\#9 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/9) `open`: Remove divider from FPGA
**Labels**: `Gateware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:21](https://github.com/HaddingtonDynamics/Dexter/issues/9):

It may be that a divider in the FPGA causes the #2  issue. Removing it and using a different system may help. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:14](https://github.com/HaddingtonDynamics/Dexter/issues/9#issuecomment-721922313):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/9)


-------------------------------------------------------------------------------

# [\#8 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/8) `open`: 21 bit position accumulators 
**Labels**: `Gateware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:19](https://github.com/HaddingtonDynamics/Dexter/issues/8):

Increasing the resolution of the positioning system to accommodate higher gear ratios in some harmonic drives. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-07-28 00:20](https://github.com/HaddingtonDynamics/Dexter/issues/8#issuecomment-408568201):

@kgallspark Is this even needed now that we understand the 100/1 drives won't manage the torque?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-04-24 03:05](https://github.com/HaddingtonDynamics/Dexter/issues/8#issuecomment-618776243):

This is needed for the rail system to allow great range of motion using the extra stepper driver.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-07-13 23:40](https://github.com/HaddingtonDynamics/Dexter/issues/8#issuecomment-657877733):

This was done for the HDI to support the higher ratios for J6 and J7 for the HDI, but could be useful for the other joints if a higher gear ratio is needed.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:12](https://github.com/HaddingtonDynamics/Dexter/issues/8#issuecomment-721920891):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/8)


-------------------------------------------------------------------------------

# [\#7 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/7) `open`: Eliminate mechanical Hysteresis / backlash
**Labels**: `Hardware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:16](https://github.com/HaddingtonDynamics/Dexter/issues/7):

Although the ultra precise encoder system used in each joint removes all backlash during operation, mechanical issues during calibration of the encoder disks can remain, causing slightly uneven motion and minor non-linearity in positioning. 

We have assumed this is caused by the belts so perhaps we need to go back to Kevlar belts? Dual belts?

But it may be caused by the harmonic drives when they are exposed to side loads. The Cycloidal Drive ( see #6 ) may remove this issue.

Or perhaps the Motors shifting because the screws aren't exactly the right size? 




#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:11](https://github.com/HaddingtonDynamics/Dexter/issues/7#issuecomment-721920446):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/7)


-------------------------------------------------------------------------------

# [\#6 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/6) `open`: Cycloidal Wave transmission
**Labels**: `Hardware`, `enhancement`, `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:10](https://github.com/HaddingtonDynamics/Dexter/issues/6):

The Harmonic Drives used in current Dexter versions are difficult to source, expensive and may have issues with backlash due to side loads. Cycloidal Drives hold great promise: It may even be possible to 3D print them with a high end printer like the [Markforge](https://markforged.com/)

If you have experience with this, we want to hear from you.

https://en.wikipedia.org/wiki/Cycloidal_drive


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-07-28 00:10](https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-408567306):

We are starting to have some success with this design. 

https://twitter.com/HDRobotic/status/1017916434230304769

A new version with better structure to prevent warping under side loads is on the way.

#### <img src="https://avatars0.githubusercontent.com/u/34084363?v=4" width="50">[BryanHaven](https://github.com/BryanHaven) commented at [2018-10-02 16:37](https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-426343566):

Would printing this on a Form2 in one of the engineered resins be useful?

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-02 21:20](https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-426434532):

Thanks @BryanHaven  ! The cycloidal drive design we are working on actually has bearings and other parts inserted during the print job, which really wouldn't work with the liquid resins. They also probably need the strength of the Onyx carbon fiber filament from our Markforged printers. 

There are other parts that it might be interesting to see on a resin printer, such as the code disks. If you want to try one of those, check the STL files at:
https://www.thingiverse.com/thing:2108244/files
and search the page for "CodeDisk". The DIFF ones probably aren't a good test, as they are pretty low count, but the base, end arm, or pivot disks would be interesting to try. The key is that the resolution must be very high, and the material totally opaque.

#### <img src="https://avatars0.githubusercontent.com/u/34084363?v=4" width="50">[BryanHaven](https://github.com/BryanHaven) commented at [2018-10-02 22:11](https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-426447886):

Hi James,

I’ve been reading up on the cycloidal drives and was curious if you’re using a dual plate or is vibration not an expected issue? Any concerns regarding lateral forces on the output?

Thanks for the info,I’m looping in Stephen who has the Form2. 

I think the Grey Pro resin would do the trick for the encoders. Just a matter of getting the supports right. 

Stephen, what are your thoughts?

Bryan

Sent from my iPhone

> On Oct 2, 2018, at 5:20 PM, JamesNewton <notifications@github.com> wrote:
> 
> Thanks Bryan! The cycloidal drive design we are working on actually has bearings and other parts inserted during the print job, which really wouldn't work with the liquid resins. They also probably need the strength of the Onyx carbon fiber filament from our Markforged printers.
> 
> There are other parts that it might be interesting to see on a resin printer, such as the code disks. If you want to try one of those, check the STL files at:https://www.thingiverse.com/thing:2108244/files
> 
> https://www.thingiverse.com/thing:2108244/files
> and search the page for "CodeDisk". The DIFF ones probably aren't a good test, as they are pretty low count, but the base, end arm, or pivot disks would be interesting to try. The key is that the resolution must be very high, and the material totally opaque.
> 
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub, or mute the thread.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-02 22:56](https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-426457498):

I've started a new issue #39  to continue with the idea of using a resin printer for the encoder disks.

@JamesWigglesworth is the guy to ask about the design of the cycloidal drive, but as I understand it, there are 3 plates, back, middle and front, because there are actually 2 drives in one unit: A 5 and a... 3? More information here:
https://hackaday.com/2018/08/24/a-peek-at-the-mesmerizing-action-of-a-cycloidal-drive/#comment-4976153

(fyi, when you reply via email, it does post that publically here. I mention because some people aren't aware of that).

#### <img src="https://avatars0.githubusercontent.com/u/34084363?v=4" width="50">[BryanHaven](https://github.com/BryanHaven) commented at [2018-10-02 23:08](https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-426460041):

I am Stephen and my contribution to the conversation is I have a form2 and
have used a lot of resin.

I attached a Form2 file (readable with preform, downloadable
https://formlabs.com/tools/preform/) of how I'd to the print of the Diff
and Pivot disks.  Light sanding on the back and outside and away you go.
Nice and simple.  I hope.  I'm not an expert on encoders, but I understand
that the spaces need to be really, REALLY uniform, so I'd want some way to
verify that.

I have no idea how to do that.

What I can do is send you a gray normal print of it in the next week or so
that you can evaluate.

The printing cost is going to be minimal (about $1.80) and shipping to a
US address about $7.20 (flat rate).  Unless/until this becomes a bigger
thing with more prints I'm happy to do this for the good fo the community
and our future robot overlords.



On Tue, Oct 2, 2018 at 3:11 PM Bryan Haven <hobbit1@mac.com> wrote:

> Hi James,
>
> I’ve been reading up on the cycloidal drives and was curious if you’re
> using a dual plate or is vibration not an expected issue? Any concerns
> regarding lateral forces on the output?
>
> Thanks for the info,I’m looping in Stephen who has the Form2.
>
> I think the Grey Pro resin would do the trick for the encoders. Just a
> matter of getting the supports right.
>
> Stephen, what are your thoughts?
>
> Bryan
>
> Sent from my iPhone
>
> On Oct 2, 2018, at 5:20 PM, JamesNewton <notifications@github.com> wrote:
>
> Thanks Bryan! The cycloidal drive design we are working on actually has
> bearings and other parts inserted during the print job, which really
> wouldn't work with the liquid resins. They also probably need the strength
> of the Onyx carbon fiber filament from our Markforged printers.
>
> There are other parts that it might be interesting to see on a resin
> printer, such as the code disks. If you want to try one of those, check the
> STL files at:https://www.thingiverse.com/thing:2108244/files
>
> https://www.thingiverse.com/thing:2108244/files
> and search the page for "CodeDisk". The DIFF ones probably aren't a good
> test, as they are pretty low count, but the base, end arm, or pivot disks
> would be interesting to try. The key is that the resolution must be very
> high, and the material totally opaque.
>
> —
> You are receiving this because you commented.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-426434532>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/AggWC5umW3LNzr1AfsrHSCmzFxcTvwGeks5ug9imgaJpZM4Vk0Ly>
> .
>
>

-- 
Stephen Rider

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-10-02 23:18](https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-426461915):

Thanks Stephen / Brian. It would be great if you could respond with that on:
https://github.com/HaddingtonDynamics/Dexter/issues/39
 instead.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 19:03](https://github.com/HaddingtonDynamics/Dexter/issues/6#issuecomment-721916286):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/6)


-------------------------------------------------------------------------------

# [\#5 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/5) `closed`: Startup repeatability
**Labels**: `Firmware`, `Hardware`, `enhancement`, `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-28 00:02](https://github.com/HaddingtonDynamics/Dexter/issues/5):

Having a way for Dexter to find "home" position automatically would be a wonderful help. This will both allow it to accurately interact with a work surface or other object via "dead reckoning" (no need to touch or be guided to a starting point). It will also removed the need to calibrate Dexter on startup because the prior calibration can be applied immediately. 

Currently, the solution to this is to add a "dial" or little knob to each motor shaft. The robot is set to a perfect zero position once during manufacture (with a test stand) then the dials are installed and their correct positions marked. While powered off, the robot is move close to the home position, then each dial is turned until it lines up with the known home position.

Automated methods of solving this problem include:
- An index pulse on each joint encoder. The issue with this is the cost of an addition sensor and extra size of the disk. It may be possible to get the same effect by filling in one of the regular slots with a semi-transparent material (it looks like "Elmers Washable Clear Glue" works well) so that the slot is still there, still the same width, but doesn't "open" as far as the other slots. On power up, each joint would be "wiggled" until the index slot is detected. Redundancy is provided by the fact that each sensor should see the same effect, some fixed number of degrees apart.
- A mechanical home switch on each motor shaft. Just like the dials, the arm would be preset to near the home position, then on power up, each joint would be "wiggled" until the home switch closes.
- A "garage" or "dock" where the tool interface must be placed by the user before power up. The robot can even drive the tool interface into the edges of the dock to ensure it is well seated before setting that position as home. Or that position may be "pre-home" and home is a known number of degrees on each joint away from the pre-home position. So the robot finds pre-home, translates each joint to a new position (home) and then zeros out it's position making that home. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-05-19 17:09](https://github.com/HaddingtonDynamics/Dexter/issues/5#issuecomment-493774216):

In order to find position faster after power up in an unknown position, a set of index pulses, instead of just one, could be used.

If the gap between index pulses is different on the two sides of the center "home" index pulse, then the correct direction to rotate to reach home. E.g. if there are an odd number of regular sized eyes between index pulses on one side of home and an even number on the other side, a small movement in any direction from any position should tell us which way to move to reach home.

If the count of regular sized eyes between index pulses increases as you move away from home, then the exact position can be found faster. E.g. on one side, there might be 4, then 6, 8 regular eyes between indexes and on the other side, 5, 7, and 9.

#### <img src="https://avatars3.githubusercontent.com/u/1184637?v=4" width="50">[cfry](https://github.com/cfry) commented at [2019-05-20 17:05](https://github.com/HaddingtonDynamics/Dexter/issues/5#issuecomment-494071723):

Clever!
_____
Lots of games could be played here.
For instance, the idea of partially covering a slot means
we effectively get 2 bits from it, ie "that it is a slot"
and that it is "partial or full".
But can we get more bits out of it? ie
1/4 covered, 1/2 covered, 3/4 covered?
and apply that to James N's trick to tell
how far a slot is from home?
Maybe this interferes too much with the normal accuracy.
A 2nd row of slots, closer to disc center, lower rez but
more bits per slot as I describe above?
Transparently colored slots?
Just throwing some more cards on the table.

On Sun, May 19, 2019 at 1:09 PM JamesNewton <notifications@github.com>
wrote:

> In order to find position faster after power up in an unknown position, a
> set of index pulses, instead of just one, could be used.
>
> If the gap between index pulses is different on the two sides of the
> center "home" index pulse, then the correct direction to rotate to reach
> home. E.g. if there are an odd number of regular sized eyes between index
> pulses on one side of home and an even number on the other side, a small
> movement in any direction from any position should tell us which way to
> move to reach home.
>
> If the count of regular sized eyes between index pulses increases as you
> move away from home, then the exact position can be found faster. E.g. on
> one side, there might be 2 then 4, 6, 8 regular eyes between indexes and on
> the other side, 3, 5, 7, and 9.
>
> —
> You are receiving this because you are subscribed to this thread.
> Reply to this email directly, view it on GitHub
> <https://github.com/HaddingtonDynamics/Dexter/issues/5?email_source=notifications&email_token=AAJBG7JFNWNNQBNYBRNI5OLPWGCT5A5CNFSM4FMTH5MKYY3PNVWWK3TUL52HS4DFVREXG43VMVBW63LNMVXHJKTDN5WW2ZLOORPWSZGODVXGLCA#issuecomment-493774216>,
> or mute the thread
> <https://github.com/notifications/unsubscribe-auth/AAJBG7IK6IDYLXHCTC3QHXDPWGCT5ANCNFSM4FMTH5MA>
> .
>

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-11-19 00:28](https://github.com/HaddingtonDynamics/Dexter/issues/5#issuecomment-555274068):

this issue is effectively closed for the HDI robots.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 18:11](https://github.com/HaddingtonDynamics/Dexter/issues/5#issuecomment-721890871):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/5)


-------------------------------------------------------------------------------

# [\#4 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/4) `open`: Skins
**Labels**: `Hardware`, `enhancement`, `help wanted`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-27 23:51](https://github.com/HaddingtonDynamics/Dexter/issues/4):

We need skins to cover the exposed cables, electronics, bearings, encoders, etc... to protect them, and reassure customers. They could be 3D printed or Vacuum molded (over 3D printed molds) or possibly formed from foam. 

Some work on this has already been done (search for "Skin") for the version 1 Dexter<BR>
https://www.dropbox.com/sh/5bdyhcyyrf3x53k/AAAagpOvq-TxkVKE1Ax-uodEa/STLs?dl=0&lst=
<BR>But it needs to be updated for recent changes (e.g. the new diff, HD lower arm)

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2019-04-05 00:21](https://github.com/HaddingtonDynamics/Dexter/issues/4#issuecomment-480108103):

Dexter HD skins are being developed in Fusion 360. The link is<br>
https://a360.co/2UpgNgs

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 18:10](https://github.com/HaddingtonDynamics/Dexter/issues/4#issuecomment-721890557):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/4)


-------------------------------------------------------------------------------

# [\#3 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/3) `open`: Dexter moves when changing from Follow mode to Keep mode.
**Labels**: `Gateware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-27 22:26](https://github.com/HaddingtonDynamics/Dexter/issues/3):

When entering Keep mode, Dexter will return to the last commanded position, which may not be the current position after movement in Follow mode. Transitioning from Follow to Keep, at the current position, without motion is an outstanding issue. 

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-08-27 22:55](https://github.com/HaddingtonDynamics/Dexter/issues/3#issuecomment-682231450):

Question: Why can't we send a command to change the last commanded position and also clear the PID DELTA used in Follow mode at the same time? E.g. make a new oplet that has the DexRun.c firmware do those two things in quick succession?

One of the FPGA addresses seems to indicate that it resets the built up PID delta. Is that correct?
`78 RESET_PID_AND_FLUSH_QUEUE: bit 0 resets PID_DELTA. Bit 1 is E_STOP? Set to all zero for normal operation.`

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 18:07](https://github.com/HaddingtonDynamics/Dexter/issues/3#issuecomment-721889141):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/3)


-------------------------------------------------------------------------------

# [\#2 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/2) `closed`: Dexter droops, loses position, zaxis error.
**Labels**: `Hardware`


#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-07-27 22:05](https://github.com/HaddingtonDynamics/Dexter/issues/2):

While working with Dexter, you might notice problems with it not being at the correct height when reaching down to the surface, or "drooping" or not lifting when commanded. Most of this is caused by problems with Joint 2 (the main "shoulder" joint) or Joint 3 (the "elbow"), but we've seen several things that cause this problem so we are documenting all the possible causes here:

1. The stepper motor shafts on Joints 2 and 3 can easily slip inside the 3D printed adapter from the motor shaft to the inside of the "harmonic drive". Since the motor shaft is what holds the wave generator in, when the shaft comes loose, the generator can fall out.* To fix: Carefully remove the drive or it's wave generator* and adapter and then mung (MUtilate, Nurl, Gorge) the motor shaft with small end cutters or other available tool. Apply a small amount of a high end adhesive to the inside of the adapter (the [DP420](https://www.amazon.com/Scotch-Weld-Epoxy-Adhesive-DP420-1-69fl/dp/B07FQQGP96) [Epoxy](http://techref.massmind.org/techref/adhesives.htm#Epoxy) is recommended, but the metalized JB weld, #8276 has been used) and carefully slide it back in. Take care not to push it too far in as that will cause binding. Let cure before moving.

_Note: Later model (2018) Dexters have a motor with "D" shaft which has a flat on one side and is longer to avoid this issue_

2. The adapter can also come loose from the wave generator. This is fairly rare, but can happen especially if there is an alignment problem. This, again, causes the joint to lose traction and/or the wave generator to fall out.* In this case, the solution is a bit of low viscosity super glue carefully applied between the adapter and inner hub of the wave generator without disassembly or after re-assembly. Be very careful to avoid getting any glue in the wave generator. Let sit.

*Be very careful re-inserting the wave generator.  It is best to try slightly different positions until you find one that slips in easily. However, it can be accidentally inserted such that the teeth are not evenly divided between the two nodes of the wave generator. In that case, the joint will jam up and you won't be able to "back drive" it. To fix it, you should be able to manually spin the inner motor shaft until the teeth pop over into the correct position. At that point, the joint may start working correctly again. Or the wave generator may be damaged.

3. The harmonic drives will bind or jam if they are not perfectly aligned. Loosening, moving and tightening the mounts can help. Also manually rotating the inner shaft / adapter / wave generator can work out the "kinks"

4. Stepper motor driver weakness. In extreme heat, especially when the motor board has been modified to increase the stepper drive, the driver chip can overheat and go into thermal shutdown to prevent burn out. This shows up as a "pulsing" where the joint grips, then sags at a rate of about once per second. Blowing on the chip will temporarily stop the issue. Note that the slipping issues mentioned above can present as a weak stepper motor, where a little "help" will resolve the issue; but this is almost certainly because the joint is _slipping_ and not due to a motor or driver problem. When the driver shuts down, it cycles on and off and is not just steadily weaker. Also, a stepper motor which is losing steps makes a distinctive vibrating noise; it is not quiet, and the slipping is usually very quiet. To fix: 
<BR>- Add small heatsinks to the driver chips with thermal adhesive. Take care not to short the surface mount components around the driver chips. 
<BR>- Add [a small fan](https://www.mouser.com/ProductDetail/108-AFB0405MA-A) directly over the motor drivers. 
<BR>- Reduce the drive current back to the original spec's if the motor board was modified to increase it.

_Note: Due to the fact that the Joint 2 (and 3) motors are buried inside the 3D printed housings, it is a really bad idea to get them very hot, especially if the housings were printed in PLA or other plastic which can deform when heated. Although the structure of the robot is all the stronger materials, some motor mounts, shaft adapters, etc... are plastic and a loss of rigidity can cause slipping, alignment, and binding issues._

5. Intermittent Z axis position creap. Some users have notice and reported that even a fully functional arm can occasionally drift on the Z axis. E.g. a job that was working at the correct height above a surface, will suddenly move to a slightly different height. Adjusting the job script to compensate results in many more cycles at the correct height, but then suddenly it will move to the wrong height again. We have not been able to reproduce this under test conditions and so are not sure what might cause it. If you can reliably reproduce this problem, please contact us. It is important to eliminate all of the issues mentioned previously before arriving at this diagnosis.




-------------------------------------------------------------------------------

# [\#1 Issue](https://github.com/HaddingtonDynamics/Dexter/issues/1) `closed`: Tinyduino returns garbage via serial link

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) opened issue at [2018-04-10 01:06](https://github.com/HaddingtonDynamics/Dexter/issues/1):

It programs ok, appears to run programs correctly, e.g. the ASCII table example, but the data that shows up in the Serial monitor window is just garbage. 

When I hook my scope up to the serial pins, I see valid data. It's a SmartScope (lab-nation.com) so it has a serial data decoder built in. That seems to see valid data. But the data returned to the PC is still garbage. I ran it all the way down to 300 baud without any change. I tried using RealTerm, it also gets garbage. Removed the prototype board, no change.

It's as if the clock in the USB adapter is off, but if that were the case, it wouldn't program, right? And it does program, at 57,600 no issues. 

Same PC programs the same sketch into a standard Arduino Uno and gets the correct values back. 

http://forum.tinycircuits.com/index.php?topic=1901.msg3730#msg3730

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2018-04-10 01:10](https://github.com/HaddingtonDynamics/Dexter/issues/1#issuecomment-379941784):

The problems is the selection of the _processor_ as well as the selection of the _board_. The Tinyduino 
 is a "Arduino Pro or Pro Mini board" which you select from the Tools / Boards menu. But it comes in both 5 volt 16MHz and 3.3 volt 8MHz versions. After you select the correct board, another option appears on the Tools menu called "Processor" and under that, you must select "Atmega 328 (3.3v 8MHz)". Once you do that, it works just fine.

#### <img src="https://avatars0.githubusercontent.com/u/419392?v=4" width="50">[JamesNewton](https://github.com/JamesNewton) commented at [2020-11-04 18:06](https://github.com/HaddingtonDynamics/Dexter/issues/1#issuecomment-721888294):

Kamino cloned this issue to [HaddingtonDynamics/OCADO](https://github.com/HaddingtonDynamics/OCADO/issues/2)


-------------------------------------------------------------------------------

