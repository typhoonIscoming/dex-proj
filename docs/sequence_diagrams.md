# DEX Project Sequence Diagrams

这些时序图描述了 DEX 项目中的核心业务流程。您可以直接在支持 Mermaid 的编辑器（如 Cursor, Obsidian, GitHub）中查看，也可以将其复制到 [draw.io](https://app.diagrams.net/) 中（使用 `Arrange -> Insert -> Advanced -> Mermaid`）生成可编辑的图表。

## 1. LP 添加流动性 (Add Liquidity)

LP 用户通过前端界面添加流动性，实际上是与 `PositionManager` 交互，最终获得一个代表头寸的 NFT。

```mermaid
sequenceDiagram
    autonumber
    actor User as LP (用户)
    participant FE as Frontend (前端)
    participant Token as ERC20 Token
    participant PM as PositionManager
    participant Pool as Pool (资金池)

    Note over User, FE: 用户输入两个代币数量和价格区间

    User->>FE: 点击 "Add Liquidity"
    
    rect rgb(240, 248, 255)
        Note right of User: 1. 授权代币
        FE->>Token: approve(PositionManager, amount)
        Token-->>FE: Success
    end

    rect rgb(255, 250, 240)
        Note right of User: 2. 铸造头寸 (Mint)
        FE->>PM: mint(MintParams)
        
        activate PM
        PM->>PM: 计算所需的 Liquidity 数量
        
        PM->>Pool: mint(recipient, liquidity, data)
        activate Pool
        
        Note right of Pool: 计算需要扣除的代币数量 (amount0, amount1)
        
        Pool->>PM: mintCallback(amount0, amount1, data)
        activate PM
        Note right of PM: 回调函数：执行真正的转账
        PM->>Token: transferFrom(User, Pool, amount)
        Token-->>Pool: 代币到账
        deactivate PM
        
        Pool-->>PM: 返回实际消耗的 amount0, amount1
        deactivate Pool

        PM->>PM: 记录头寸信息 (PositionInfo)
        PM->>User: Mint NFT (ERC721)
        PM-->>FE: 交易成功
        deactivate PM
    end
```

## 2. 交易者 SWAP (Swap)

交易者通过 `SwapRouter` 进行代币兑换。

```mermaid
sequenceDiagram
    autonumber
    actor User as Trader (交易者)
    participant FE as Frontend (前端)
    participant Token as ERC20 Token
    participant Router as SwapRouter
    participant Pool as Pool (资金池)

    Note over User, FE: 用户输入 TokenIn 和 TokenOut

    rect rgb(240, 248, 255)
        Note right of User: 1. 询价 (Quote)
        FE->>Router: quoteExactInput(params) (Static Call)
        Router-->>FE: 返回预估 amountOut
    end

    User->>FE: 点击 "Swap"

    rect rgb(240, 248, 255)
        Note right of User: 2. 授权代币
        FE->>Token: approve(SwapRouter, amountIn)
        Token-->>FE: Success
    end

    rect rgb(255, 250, 240)
        Note right of User: 3. 执行交易
        FE->>Router: exactInput(ExactInputParams)
        activate Router
        
        loop 路径中的每个 Pool (如多跳交易)
            Router->>Pool: swap(recipient, zeroForOne, amount, limit, data)
            activate Pool
            
            Note right of Pool: 计算交换结果、更新价格和 Tick
            
            Pool->>Router: swapCallback(amount0Delta, amount1Delta, data)
            activate Router
            Note right of Router: 回调函数：支付代币
            Router->>Token: transferFrom(User, Pool, amountIn)
            Token-->>Pool: 代币到账
            deactivate Router
            
            alt 最后一跳
                Pool->>User: 转账 TokenOut
            else 中间跳
                Pool->>Router: 转账 TokenOut (作为下一跳输入)
            end
            
            Pool-->>Router: 返回 swap 结果
            deactivate Pool
        end

        Router-->>FE: 交易成功
        deactivate Router
    end
```

## 3. LP 收取手续费 (Collect Fees)

在集中流动性模型中，手续费不会自动复投，而是累积在头寸中，需要 LP 主动触发 `collect` 来提取。

```mermaid
sequenceDiagram
    autonumber
    actor User as LP (用户)
    participant FE as Frontend (前端)
    participant PM as PositionManager
    participant Pool as Pool (资金池)

    User->>FE: 点击 "Collect Fees"

    FE->>PM: collect(positionId, recipient)
    activate PM
    
    PM->>PM: 验证 NFT 所有权 (isAuthorized)
    
    PM->>Pool: collect(recipient, amount0Max, amount1Max)
    activate Pool
    
    Note right of Pool: 检查该头寸累积的 tokensOwed (手续费)
    
    Pool->>User: 直接转账 (Transfer Token0 & Token1)
    
    Pool-->>PM: 返回实际提取金额
    deactivate Pool

    PM->>PM: 更新头寸记录 (清零 tokensOwed)
    
    opt 如果流动性为0且已提空
        PM->>PM: Burn NFT (销毁头寸)
    end

    PM-->>FE: 交易成功
    deactivate PM
```
