# Kong 请求头改写

Kong 自定义插件，根据特定的header值，来改写(添加)请求头。

注： rewrite阶段执行，只能作为全局插件使用。

## 使用：

安装插件，修改Kong配置，加载自定义插件，运行命令：

``` shell
# 第一次运行要初始化插件数据库
kong migrations up  

# 重启Kong
kong restart  

#或者不重启加载
kong prepare
kong reload
```

启动插件：
```
POST http://{{endpoint}}/plugins 
Content-Type: application/x-www-form-urlencoded

name=header-rewrite&config.match={header}&config.rewrite={header}
```

新增规则：

```
POST http://{{endpoint}}/header_rewrite
Content-Type: application/json

{
  "match" : "123456",
  "rewrite" : "g1"
}
```

实现效果： 

```
原请求头：
match_header: 123456

改写后：
match_header: 123456
rewrite_header: g1
```


查询规则：

```
GET  http://{{endpoint}}/header_rewrite
```

删除规则：

```
DELETE http://{{endpoint}}/header_rewrite/{{you_match}}
```

