#import "/template.typ": calver, note, post

#show: post.with(
  slug: "pixel-flash-aosp-images",
  title: "Pixel手机刷入AOSP镜像",
  course: "AOSP开发",
  create: calver(2026, 9, 10),
  description: "记录将AOSP源码编译得到的镜像刷入Pixel手机的两种方法，其中第一种方法需要依赖Google提供的设备驱动文件（在Android16及以后Google不再提供），第二种方法通用性更强。",
  tags: ("develop", "aosp"),
  draft: false,
)

// Write the post body below.

= 前置条件

已经拉取好了所需分支的aosp源码。

= 选用什么方法？

#link(
  <method2>,
)[刷入方式二]理论上适用于任何可解锁BL的机型以及Android版本，#link(
  <method1>,
)[刷入方式一]只适用于谷歌提供了设备驱动文件的pixel设备以及Android15及之前的版本。

= 刷入方式一：刷入针对Pixel的特定build <method1>

此方法适用于谷歌提供了设备驱动文件的pixel设备（pixel
10之前的所有设备）以及Android15及以前的系统镜像刷入。

== 操作步骤

+ 获取驱动文件

  在#link(
    "https://developers.google.com/android/drivers",
  )下下载所需Android版本以及对应build id的驱动。

  下载得到的文件名称形如`google_devices-lynx-ap3a.241005.015.a2-ba978bd7.tgz`。

  使用tar命令解压这个文件，可以得到一个名为`extract-google_devices-<pixel代号>.sh`的文件。

  在*aosp根目录*下执行这个脚本，阅读完谷歌的条款之后输入`I ACCEPT`，脚本会自动把需要的驱动放到aosp的指定目录。

+ 构建所需分支的aosp镜像

  + 在aosp根目录下执行命令激活工作环境：

    ```sh
    export OUT_DIR=<...> # 个人开发偏好使用自定义out文件夹
    source build/envsetup.sh
    lunch aosp_<pixel代号>-<build id>-<build mode>
    ```

    - pixel代号：如Pixel 7a代号为lynx
    - build id：release分支形如ap3a，bp4a等，develop分支形如trunk_staging
    - build mode：开发需要一般使用userdebug或者eng，release使用为user

    lunch时可能会有找不到文件的报错：

    ```
    cat: device/google/lynx-kernels/5.10/24Q3-12318583/system_dlkm.modules.load: No such file or directory
    cat: device/google/lynx-kernels/5.10/24Q3-12318583/system_dlkm.modules.load: No such file or directory
    ```

    个人测试时即使有这样的报错也可以顺利构建并刷入。

  + 构建完整镜像：

    ```sh
    m
    ```

+ 刷入手机

  + 激活环境：

    ```sh
    export OUT_DIR=<...> # 个人开发偏好使用自定义out文件夹
    source build/envsetup.sh
    lunch aosp_<pixel代号>-<build id>-<build mode>
    ```

    虽说使用包管理器安装的android-platform-tools的adb和fastboot可能也可以正常安装，但是仍然建议使用之前构建的adb和fastboot，其次也需要激活环境后设置的`ANDROID_PRODUCT_OUT`环境变量用于fastboot刷入镜像。

  + 使用adb重启到fastboot

    ```sh
    adb reboot bootloader
    ```

    注意是`adb reboot bootloader`而不是`adb reboot fastboot`，后者会重启到fastbootd模式。

  + 使用fastboot刷入镜像

    ```sh
    fastboot flashall -w
    ```

    注意，这里的`-w`是必须加上的，刷入完整镜像必须清除数据。

    等待刷入镜像完成后设备自动重启即可。

= 刷入方式二：GSI镜像 <method2>

因为谷歌不再提供pixel设备在Android16版本之后的驱动文件与设备树信息，所以如果需要在Android16下进行开发测试，使用GSI镜像是一个比较方便的方式。

此方法主要参考了#link(
  "https://proandroiddev.com/building-flashing-a-custom-aosp-gsi-on-pixel-arm64-android-16-1313b4211c53",
)，同时参考了一些其他链接解决按照此处博客的步骤遇到的坑，详细见下。

== 操作步骤


+ 在aosp根目录下执行命令激活工作环境：

  ```sh
  export OUT_DIR=<...> # 个人开发偏好使用自定义out文件夹
  source build/envsetup.sh
  lunch aosp_arm64-<build id>-<build mode>
  ```

  注意这里的target第一部分变成了`aosp_arm64`，这就代表我们在构建GSI镜像。

+ 构建完整镜像：

  ```sh
  m
  ```

  根据#link(
    "https://proandroiddev.com/building-flashing-a-custom-aosp-gsi-on-pixel-arm64-android-16-1313b4211c53",
  )所言，这里并非一定要构建完整镜像，这里笔者没有测试，因为为了后续开发方便需要至少把adb相关的工具也构建一下，如果不在乎构建时间执行一次完整构建更方便一点。

+ 刷入vbmeta镜像

  先使用adb重启到fastboot：

  ```sh
  adb reboot bootloader
  ```

  使用fastboot刷入vbmeta镜像：

  ```sh
  fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
  ```

  `--disable-verity`和`--disable-verification`参数是必需的，必须禁用AVB完整性校验才可以顺利刷入并开机。

  #note[
    在这一步笔者遇到了下面的报错：

    ```
    fastboot: error: Failed to find AVB_MAGIC at offset: 0
    ```

    根据#link(
      "https://github.com/gogopowerjackets/razer-edge-gsi/issues/1",
    )提供的方法参考，下载老版本的platform-tools进行操作即可解决。这里也把链接里说的34.0.4版本的下载链接贴在这里：

    - Windows：#link(
        "https://dl.google.com/android/repository/platform-tools_r34.0.4-windows.zip",
      )
    - Mac：#link(
        "https://dl.google.com/android/repository/platform-tools_r34.0.4-darwin.zip",
      )
    - Linux：#link(
        "https://dl.google.com/android/repository/platform-tools_r34.0.4-linux.zip",
      )
  ]

+ 刷入system镜像

  使用fastboot重启到fastbootd模式：

  ```sh
  fastboot reboot fastboot
  ```

  使用fastboot刷入system：

  ```sh
  fastboot flash system system.img
  ```

  #note[
    根据#link(
      "https://proandroiddev.com/building-flashing-a-custom-aosp-gsi-on-pixel-arm64-android-16-1313b4211c53",
    )提供的教程，并没有要求一定需要重启到fastbootd模式，但是笔者在使用pixel10测试的时候不进入fastbootd模式就无法刷入，会有下面的报错：

    ```
    Resizing 'system_a'                                FAILED (remote: 'Invalid command resize-logical-partition:system_a:1899495424')
    fastboot: error: Command failed
    ```

    通过参考#link(
      "https://discuss.grapheneos.org/d/20058-cannot-flash-systemimg-in-my-custom-eng-build-engineering-build",
    )下的解决方案，重启到fastbootd模式才顺利刷入了。
  ]

  #note[
    2026.4.17更新

    在刷入system.img时可能会遇到报错：

    ```
    Invalid sparse file format at header magic
    ```

    但是笔者测试后尽管报错仍然可以刷入成功。
  ]

+ 清除原有的用户数据

  使用fastboot清除数据：

  ```sh
  fastboot -w
  ```

  #note[
    根据#link(
      "https://proandroiddev.com/building-flashing-a-custom-aosp-gsi-on-pixel-arm64-android-16-1313b4211c53",
    )提供的教程，这一步仅在从原厂系统刷入到GSI镜像时是必须的，笔者暂时没有测试GSI镜像互刷的效果。

    2026.4.17更新：笔者测试了一次GSI互刷，没有清除数据也没有报错。
  ]

+ 重启手机

  使用fastboot重启手机：

  ```sh
  fastboot reboot
  ```

  重启之后应该就可以正常进入GSI系统的桌面了。
