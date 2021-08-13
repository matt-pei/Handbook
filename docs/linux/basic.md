# Linux basic


#### linux开机启动引导

> 1、开机执行BIOS(基本输入输出系统)的post(上电自检)过程
>
> 2、BIOS加电自检确认硬件基本功能正常,接入可引导设备引导扇区,引导记录的第一个引导扇区加载到内存中(通常位于MBR主引导记录)   grub2通过/boot/grub/grub.cfg
>> grub引导阶段
>>
>> 阶段1
>>
>>
>> 阶段2：
>>
>> 该阶段需要从`/boot/grub2/i386-pc`目录下加载一些内核运行时的模块,该阶段主要功能是定位和和加载Linux内核到到内存中 内核相关文件在`/boot`目录下 其文件名带有前缀的vmlinuz的文件。
>
> 3、选择内核加载到内存中并执行,再此之前内核文件首先从压缩格式解压自身,解压完成后则加载`systemd`进程,并转移权限到systemd。此时引导过程结束,Linux内核和systemd处于运行状态 由于没有任何程序执行 故不能执行任何有关用户功能性的任务。
>
> 4、systemd是所有进程的父进程 负责将Linux带到一个用户可操作的状态,首先systemd挂载`/etc/fstab`中配置文件系统,包括内存交换文件或分区;其次systemd借助配置文件`/etc/systemd/system/default.target`来决定linux系统应该启动哪个状态。
> 
>> `default.target`是一个符号链接文件默认链接到`/lib/systemd/system/multi-user.target`相当于systemV系统的`runlevel3`

|SystemV 运行级别|systemd 目标态|systemd 目标态别名|描述|
|:--:|:--:|:--:|:--:|
| |`halt.target`| |停止系统运行但不切断电源|
|0|`poweroff.target`|`runlevel0.target`|停止系统运行并切断电源|
|S|`emergency.target`| |单用户模式,没有服务进程运行,文件系统也没挂载.这是一个最基本的运行级别，仅在主控制台上提供一个 shell 用于用户与系统进行交互|
|1|`rescue.target`|`runlevel1.target`|挂载了文件系统,仅运行了最基本的服务进程的基本系统,并在主控制台启动了一个 shell 访问入口用于诊断|
|2||`runlevel2.target`|多用户，没有挂载 NFS 文件系统,但是所有的非图形界面的服务进程已经运行|
|3|`multi-user.target`|`runlevel3.target`|所有服务都已运行，但只支持命令行接口访问|
|4||`runlevel4.target`|未使用|
|5|`graphical.target`|`rrunlevel5.target`|多用户,且支持图形界面接口|
|6|`reboot.target`|`runlevel6.target`|重启|
||`default.target`||这个目标态是总是multi-user.target或graphical.target的一个符号链接的别名.systemd总是通过default.target启动系统.default.target绝不应该指向halt.target、poweroff.target或reboot.target|

