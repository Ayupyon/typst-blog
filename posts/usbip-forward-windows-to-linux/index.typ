#import "/template.typ": calver, note, post

#show: post.with(
  slug: "usbip-forward-windows-to-linux",
  title: "usbip转发Windows下USB接口到Linux",
  course: "开发笔记",
  create: calver(2026, 9, 6),
  description: "记录使用Windows下的usbipd工具和Linux下的usbip工具，将Windows下的USB端口通过网络转发到Linux下使用的过程。",
  tags: ("develop", "usbip"),
  draft: false,
)

// Write the post body below.

= 问题背景

我在学校的办公机器运行Windows
10系统，这个机器主机带有一个USB-C接口，而平时用于开发的Linux机器主机没有USB-C接口，同时用于AOSP开发实验的Pixel手机只赠送了一条C-TO-C的数据线（真是太环保啦！），所以用这条数据线不能连上开发环境下的Linux主机。

因为办公机器和开发机器都位于学校内网，网络传输速度很快，同时也懒得再买一根新的A-TO-C数据线，所以尝试折腾一下通过usbip的方式，把手机连到Windows主机下，然后通过usbip把接口转发到Linux下使用。

= 配置过程

== Windows配置

在#link("https://github.com/dorssel/usbipd-win")[Windows
  usbipd仓库]的Release界面下载最新版本的msi安装包完成安装。

在终端中运行`usbipd list`可以看到所有连接到了主机的usb设备：

```
Connected:
BUSID  VID:PID    DEVICE                                                        STATE
1-2    18d1:4ee7  AOSP on ARM64                                                 Not Shared
1-12   1c4f:004b  USB 输入设备                                                  Not shared
1-13   258a:010c  USB 输入设备                                                  Not shared

Persisted:
GUID                                  DEVICE
```

#note[
  我在配置到这一步的时候，输出的usb设备列表还加上了一个警告信息：

  ```
  usbipd: warning: Unknown USB filter 'hrdevmon' may be incompatible with this software; 'bind --force' may be required.
  ```

  在谷歌上查阅对应信息时，搜索引擎内的Gemini提到`hrdevmon`是火绒的U盘保护filter，所以如果看到这个消息需要进入火绒把U盘保护关掉（进入火绒-防护中心-U盘保护），否则即使使用`bind --force`也会出现不能使用的问题。
]

这里的BUSID
1-2是我想要转发的设备，通过在管理员shell下运行`usbipd bind`来将其绑定到usbipd的转发列表中：

```
usbipd bind --busid 1-2
```

此时再运行`usbipd list`会看到1-2的状态变成了Attached：

```
Connected:
BUSID  VID:PID    DEVICE                                                        STATE
1-2    18d1:4ee7  AOSP on ARM64                                                 Attached
1-12   1c4f:004b  USB 输入设备                                                  Not shared
1-13   258a:010c  USB 输入设备                                                  Not shared

Persisted:
GUID                                  DEVICE
```

== Linux配置

使用包管理工具安装usbip（我使用的发行版为Debian 13）：

```
sudo apt update
sudo apt install usbip
```

使用`usbip list -r <remote-ip>`查看对应主机绑定的转发端口：

```
$ sudo usbip list -r <remote-ip>
Exportable USB devices
======================
 - <remote-ip>
        1-2: Google Inc. : Nexus/Pixel Device (charging + debug) (18d1:4ee7)
           : USB\VID_18D1&PID_4EE7\5C121FDCR001GK
           : (Defined at Interface level) (00/00/00)
           :  0 - Vendor Specific Class / unknown subclass / unknown protocol (ff/42/01)
```

这里可以看到Windows主机上的1-2端口可以被Linux主机上的usbip发现，使用`usbip attach`连接它：

```
sudo usbip attach -r <remote-ip> -b 1-2
```

成功返回之后，就可以通过`lsusb`找到连接到的远程USB设备了：

```
$ lsusb
...
Bus 003 Device 003: ID 18d1:4ee7 Google Inc. Nexus/Pixel Device (charging + debug)
...
```

接下来就可以和正常使用本地USB端口连接的设备一样使用它了，只不过数据交换速率会受到网速限制。
