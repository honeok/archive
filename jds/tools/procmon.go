package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"
)

type ProcessInfo struct {
	PID         int
	Name        string
	CPUPercent  float64
	MemoryGB    float64
}

type ProcessSample struct {
	UTime  uint64
	STime  uint64
	Memory uint64
}

func main() {
	// 第一次采样
	samples1, err := getProcessSamples()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	// 等待1秒
	time.Sleep(1 * time.Second)

	// 第二次采样并计算结果
	processes, err := getProcessInfo(samples1)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	// 按CPU使用率排序
	sort.Slice(processes, func(i, j int) bool {
		return processes[i].CPUPercent > processes[j].CPUPercent
	})

	// 显示表头（黄色）
	fmt.Printf("\033[33m%-8s %-20s %-10s %-12s\033[0m\n", "PID", "NAME", "CPU%", "MEMORY(GB)")
	fmt.Println(strings.Repeat("-", 50))

	// 显示前10个进程
	for i := 0; i < len(processes) && i < 10; i++ {
		p := processes[i]
		fmt.Printf("%-8d %-20s %-10.2f %-12.3f\n",
			p.PID,
			p.Name[:min(20, len(p.Name))],
			p.CPUPercent,
			p.MemoryGB)
	}
}

func getProcessSamples() (map[int]ProcessSample, error) {
	samples := make(map[int]ProcessSample)

	procDir, err := os.Open("/proc")
	if err != nil {
		return nil, err
	}
	defer procDir.Close()

	pids, err := procDir.Readdirnames(-1)
	if err != nil {
		return nil, err
	}

	for _, pidStr := range pids {
		pid, err := strconv.Atoi(pidStr)
		if err != nil {
			continue
		}

		statPath := filepath.Join("/proc", pidStr, "stat")
		statData, err := ioutil.ReadFile(statPath)
		if err != nil {
			continue
		}

		fields := strings.Fields(string(statData))
		if len(fields) < 23 {
			continue
		}

		utime, _ := strconv.ParseUint(fields[13], 10, 64)
		stime, _ := strconv.ParseUint(fields[14], 10, 64)

		samples[pid] = ProcessSample{
			UTime: utime,
			STime: stime,
		}
	}

	return samples, nil
}

func getProcessInfo(samples1 map[int]ProcessSample) ([]ProcessInfo, error) {
	var processes []ProcessInfo
	numCPU := float64(runtime.NumCPU()) // 获取CPU核心数

	procDir, err := os.Open("/proc")
	if err != nil {
		return nil, err
	}
	defer procDir.Close()

	pids, err := procDir.Readdirnames(-1)
	if err != nil {
		return nil, err
	}

	for _, pidStr := range pids {
		pid, err := strconv.Atoi(pidStr)
		if err != nil {
			continue
		}

		// 读取stat文件
		statPath := filepath.Join("/proc", pidStr, "stat")
		statData, err := ioutil.ReadFile(statPath)
		if err != nil {
			continue
		}

		// 读取status文件
		statusPath := filepath.Join("/proc", pidStr, "status")
		statusData, err := ioutil.ReadFile(statusPath)
		if err != nil {
			continue
		}

		proc := parseProcessInfo(pid, string(statData), string(statusData), samples1, numCPU)
		if proc != nil {
			processes = append(processes, *proc)
		}
	}

	return processes, nil
}

func parseProcessInfo(pid int, stat, status string, samples1 map[int]ProcessSample, numCPU float64) *ProcessInfo {
	fields := strings.Fields(stat)
	if len(fields) < 23 {
		return nil
	}

	// 获取进程名称
	name := fields[1][1 : len(fields[1])-1]

	// 计算CPU使用率
	utime2, _ := strconv.ParseUint(fields[13], 10, 64)
	stime2, _ := strconv.ParseUint(fields[14], 10, 64)
	
	sample1, exists := samples1[pid]
	if !exists {
		return nil // 如果第一次采样没有这个进程，跳过
	}

	// 计算时间差（单位：jiffies）
	totalTime := float64((utime2 + stime2) - (sample1.UTime + sample1.STime))
	hertz := 100.0         // 假设时钟频率为100Hz（常见Linux默认值）
	seconds := 1.0         // 采样间隔1秒
	
	// CPU使用率 = (时间差 / (时钟频率 * 采样间隔)) * 100 / CPU核心数
	cpuPercent := (totalTime / (hertz * seconds)) * 100 / numCPU

	// 获取内存使用（转换为GB）
	var memGB float64
	for _, line := range strings.Split(status, "\n") {
		if strings.HasPrefix(line, "VmRSS:") {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				memKB, _ := strconv.ParseUint(fields[1], 10, 64)
				memGB = float64(memKB) / (1024 * 1024) // KB转为GB
			}
			break
		}
	}

	return &ProcessInfo{
		PID:        pid,
		Name:       name,
		CPUPercent: cpuPercent,
		MemoryGB:   memGB,
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}