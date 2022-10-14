

#### PrometheusAlert
```
## 飞书自定义监控模版
{{ $var := .externalURL }}{{ range $k,$v:=.alerts }}
{{ if eq $v.status "resolved" }}
**[✅恢复告警]({{ $v.generatorURL }})**
*[{{ $v.labels.alertname }}]({{ $var }})*
<font color="#02b340">告警级别</font>: {{ $v.labels.level }}
<font color="#02b340">开始时间</font>: {{ GetCSTtime $v.startsAt }}
<font color="#02b340">结束时间</font>: {{ GetCSTtime $v.endsAt }} 
<font color="#02b340">故障主机IP</font>: {{ $v.labels.instance }}
**{{ $v.annotations.description }}**
{{else}}
**[🚨监控告警通知]({{ $v.generatorURL }})**
*[{{ $v.labels.alertname }}]({{ $var }})*
<font color="#FF0000">告警级别</font>: {{ $v.labels.level }}
<font color="#FF0000">开始时间</font>: {{ GetCSTtime $v.startsAt }}
<font color="#FF0000">结束时间</font>: {{ GetCSTtime $v.endsAt }}
<font color="#FF0000">故障主机IP</font>: {{ $v.labels.instance }}
**{{ $v.annotations.description }}**
{{end}}
{{ end }}
```