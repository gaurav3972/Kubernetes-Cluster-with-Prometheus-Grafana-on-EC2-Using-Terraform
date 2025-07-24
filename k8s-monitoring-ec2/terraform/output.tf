output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = [for w in aws_instance.worker : w.public_ip]
}
