# Jenkins Pipeline

> Jenkins声明式和脚本式语法

## 1、声明式Pipeline

### 1、pipeline代码块
```
声明式pipeline在流水线上提供一种简单的语法,所有的声明式都是必须包含一个pipeline代码块
声明式pipeline中基本语法遵循Groovy语法
流水线必须是一个pipeline{}
不需要分号做为分隔符 按照行进行分割
语句块由阶段、指令、步骤、赋值语句组成

pipeline{
    // run
}
```

### 2、agent(代理)
```
agent参数:
any: 在任何可用节点上执行pipeline
none: 没有指定agent时默认
label: 在指定标签节点运行pipeline
node: 额外配置选项
    agent { node { label 'labelname' }}
    agent { label 'labelname' }
```

### 3、post
```
定义一个或多个steps
always: 无论流水线或阶段完成状态
changed: 只有流水线或阶段完成状态与之前不同时
failure: 只有流水线或阶段状态为"failure运行
success: 只有流水线或阶段状态为"success"运行
unstable: 只有流水线或阶段状态为"unstable"运行
aborted: 只有流水线或阶段状态为"aborted"运行

pipeline{
    agent any
    stages('Build'){
        stage{
            script{
                println("Building code")
            }
        }
    }

    post{
        always{
            echo "The command"
        }
    }
}

```

### 4、stages(阶段)
```
包含或一个或多个stage,至少包含一个stage指定用于连续交付 如:构建、测试、和部署
pipeline{
    agent any
    stages{
        stage('Build'){
            steps{
                // echo "Build"
                script{
                    println("Build command")
                }
            }
        }
    }
}
```

### 5、steps(步骤)
```
steps是在每个阶段中的步骤
pipeline{
    agent any
    stages{
        stage('Test'){
            setps{
                echo "Test"
                script{
                    println("Test command")
                }
            }
        }
    }
}
```

### 6、environment
```
environment定义为环境变量 或特定阶段步骤,指令指定一个键值对
pipeline{
    agent any
    environment{
        go = "golang"
    }
    stages{
        stage('Deploy'){
            environment{
                AN_ACCESS_KEY = credentials('secret-text') 
            }
            steps{
                echo "Deploy command"
            }
        }
    }
}
```

### 7、option
```
option允许从流水线内部配置特定鱼流水线的选项
buildDiscarder: 为最近流水线运行特定数量保存组件和控制台输出
disableConcurrentBuilds: 不允许同时执行流水线,可用来防止同时访问共享资源
overrideIndexTriggers: 允许覆盖分支索引触发器默认处理
skipDefaultCheckout: 在agent指令中 跳过从源代码控制检出代码默认情况
skipStagesAfterUnstabl: 在构建状态变为UNSTABLE 跳过该阶段
checkoutToSubdirectory: 在工作空间的子目录中自动执行源代码控制检出
timeout: 设置流水线运行超时时间,jenkins将终止流水线
retry: 在流水线失败时,重新尝试整个流水线的指定次数

pipeline{
    agent any
    option{
        timeout(time:3, unit: 'MINUTES') // MINUTES/HOURS
    }
    stages{
        stage('Build'){
            steps{
                echo "Build command"
            }
        }
    }
}
```

### 8、参数
```
流水线在运行时设置的参数
string 字符串类型参数
    parameters{string(name: 'DEPLOY_ENV', defaultValue: 'xxx', description: '')}
booleanParam 布尔参数
    parameters{booleanParam(name: 'DEBUG_BUILD', defaultValue: true, description: '')}

pipeline{
    agent any
    parameters{
        string(name: 'PERSON', defaultValue: 'xxx', description: '')
    }
    stages{
        stage('Build'){
            steps{
                echo "Build command"
                script{
                    println("xxx")
                }
            }
        }
    }
}
```

### 9、触发器
```
cron计划任务
    tiggers{ cron('H */5 * * 0-6') }
pollSCM与cron类似,由Jenkins定期检测源码变化
    tiggers{ pollSCM('H */1 * * 0-6') }
upstream接受逗号分割的工作字符和阈值,当字符串的任何作业以最小阈值结束时流水线被重新触发
    tiggers{ upstream(upstreamProjects: 'x1,x2', threshold: hudson.model.Result.SUCCESS) }

pipeline{
    agent any
    tiggers{
        cron('H */5 * * 0-6')
    }
    stages{
        stage('Test'){
            echo "xxxx"
        }
    }
}
```

### 10、tool
```
能够获取通过自动安装或者手动安装的工具环境变量, 如: maven/ant/gradle/npm等 工具名称需在配置中定义

pipeline{
    agent any
    tools{
        maven 'apache-maven-3.x'
    }
    stages{
        stage('Build'){
            steps{
                sh 'mvn --version'
            }
        }
    }
}
```

### 11、step
#### script
```
script步骤需在scripted-pipeline 声明流水线中执行

pipeline{
    agent any
    stages{
        stage('Build'){
            steps{
                echo "Start Building"
                script{
                    a
                }
            }
        }
    }
}
```



## 2、脚本Pipeline


