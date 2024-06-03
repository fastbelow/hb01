
# Sui 环掌战 1.0  

* click to [English](#handbattle-10) 

web3 sui move dapp

## 掌握经典,赢取无限
猜拳,这个源远流长的经典游戏,如今以全新的面貌重现在你我眼前。无论是与朋友畅快对弈,还是在虚拟世界里一决高下,这都是一个挑战智慧、捕捉时机的绝佳游戏。

## 简单规则,无穷可能
掌握猜拳的规则其实非常简单 - 石头、剪刀、布。但就是这三种基本手势,却孕育出了无穷无尽的对抗可能。你能否洞察对手的心思,在瞬息万变中做出正确的选择?

## 一起开启,全新征程
让我们一起踏上猜拳的全新征程。在这里,你将体验到紧张刺激的对抗,感受到胜利的喜悦。让经典重现光芒,让智慧与速度交织,一起开启崭新的游戏时代!

## 全链游戏

猜拳和链上相结合,让游戏体验更丰富。

没有服务端的线上对战游戏

# plan 
增加 官方 随机数

# 快乐路径

对执行的结果进行规避操作

就是办到 胜利和失败的gas费用保持一致

或无法从胜利或失败中找到规律
<br>
<br>
<br>


# Sui HandBattle 1.0 
* 点此处跳转 [中文版](#环掌战-10)

web3 sui move dapp

## Master the Classic, Claim Infinite Victories

Rock-Paper-Scissors, the age-old classic game, now presents itself in an entirely new light. Whether you're engaging in a lively match with friends or competing in the virtual realm, this game offers an excellent challenge to your wisdom and timing.

## Simple Rules, Endless Possibilities

Mastering the rules of Rock-Paper-Scissors is remarkably straightforward - rock, paper, scissors. Yet, from these three basic gestures, an infinite array of confrontational possibilities emerges. Can you discern your opponent's thoughts and make the correct choice amidst the ever-changing dynamics?

## Embark on a New Adventure

Let us embark on a new journey of Rock-Paper-Scissors together. Here, you will experience the thrilling intensity of competition and savor the joy of victory. Let the classic game shine anew, as wisdom and speed intertwine to usher in a brand-new era of gaming!

## Full-Chain Gaming

By integrating Rock-Paper-Scissors with blockchain technology, we can elevate the gaming experience to new heights.

Decentralized online multiplayer without any server infrastructure

# plan
Incorporate an official on-chain random number generator


# testnet Random

sui client call --package 0xed7fa85ae32ef0c9b3005600ac7edec1cf42b54e4b5db9a9d735d2d220dd6368 --module tbase --function showrandom --args 0x8 --gas-budget 100000000


```
    entry fun showrandom(r: &Random, ctx: &mut TxContext){
        
        // 2024
        // let mut generator = new_generator(r, ctx);
        // let mut v = random::generate_u8_in_range(&mut generator, 1, 100);
        // 2024 end

        // 2023
        let generator = new_generator(r, ctx);
        let v = random::generate_u8_in_range(&mut generator, 1, 100);
        // 2023 end
        event::emit(TrndExt{
            trnd_ext:v
        });
    }
```
# happy path

Perform avoidance operations on the results of execution

It's about achieving consistent gas costs for both victory and failure

Or unable to find patterns from victory or failure

