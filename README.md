# YLProgressHUD
macos 开发  HUD

pod 安装

```objective-c
pod 'YLProgressHUD'
```

----

适配暗黑模式，可自定义显示的模式

```objective-c
// 默认跟随主题，可设置为 YLProgressHUDStyleBlack（亮色主题使用）， YLProgressHUDStyleWhite（暗黑主题使用）
[YLProgressHUDConfig share].style = YLProgressHUDStyleAuto;
```

----

>成功
<img width="482" alt="image" src="https://user-images.githubusercontent.com/12909260/210725153-a000a5a1-d898-4a83-9877-a6e120c6b17b.png">

>失败
<img width="483" alt="image" src="https://user-images.githubusercontent.com/12909260/210725209-50a956c3-fd1b-4c26-96d8-9f73219df841.png">

>文字
<img width="482" alt="image" src="https://user-images.githubusercontent.com/12909260/210725271-a1062de7-dc8d-4aae-943a-7a85e1ac29f2.png">

>loading
<img width="483" alt="image" src="https://user-images.githubusercontent.com/12909260/210725326-7cfe9cd9-f0bb-4ac7-b5ad-beeb96e31d0d.png">

>进度
<img width="486" alt="image" src="https://user-images.githubusercontent.com/12909260/210738081-fc455a8b-5a8c-46db-b37e-044ffb3adc8f.png">

>暗黑模式
<img width="484" alt="image" src="https://user-images.githubusercontent.com/12909260/210726111-00b0030f-133e-40ee-a636-d0aa66a0af98.png">
