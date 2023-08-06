# Limpando o que não é usado

Você irá notar que depois de muitos comandos para lá e para cá, muitas coisas ficaram para trás, como containers parados, imagens não "funcionais" e etc. Para limparmos essa bagunça, execute o comando abaixo:

```
docker system prune
```

Você irá receber algo do tipo:

```
rafael @ nazgul ~
└─ $ ▶ docker system prune
WARNING! This will remove:
        - all stopped containers
        - all networks not used by at least one container
        - all dangling images
        - all build cache
Are you sure you want to continue? [y/N] y
Deleted Containers:
7ed46aef747a7726285ecde46f7fbcd37fb932e1d106a5552a5ec6205cb45f2f
847d0f4d36f2b295804778ea69d33e3f9e4fbaf968fec9c244126955aba50e9b
a47ad7b67d69698896b290f6daf7e4f65760a38a15a2ba10ed87e3d33ecc1032
dfcbe65a5ae70c204abec0f8a224d1373804c64a927ada38f09d773aca29020d
62126d53d79232d6bd687a68990e5ef05b5e9e3f8e678286994e2370e9c6faed
b9427ac05e95b6a7256dec9d53578ed1d05c6792333917e69be5f71e074a5a50
076a96cd455ad7d7a97d2756b8bd1768aa474fccb7c73022fc94aa013ff0a274
afdf2d8219b5917ba9e110657e0364d7c9f407e1871631669912b626bf6033a8
498da065d6e5f19e27828336a9c0a72dcce284de7ccf21e469266fb8a67a7e3d
a5dadf4de7549d7923aa9a00b5851813efd8ac7f1dd2410397865bc64955af57
365ae9546d039aba3e8df2abc5132310e2ec67f54bc20e0ac6c2e5b35e55052a
5c0e6625bda621820dc18479231a7018d7c11dd6fa933c0c4842e575041a34a0
f0e9646730cd1bd8360e2fa2a71c8bfb3910968047acffe01f772c88f75b940e

Deleted Images:
deleted: sha256:2d92e5d5adbe5e207b36d93bd14d8b75919d4a118c86f4b137a9c46481b98fef
deleted: sha256:8ae3118b00c274114fd91dc96628b845e0ff4722717bfdf343c2207bad1ec01f

Total reclaimed space: 70.62MB
```
