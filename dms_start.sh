dms_name=$1
aws_region="us-east-1"
dms_arn=`aws dms describe-replication-tasks --filter Name=replication-task-id,Values="$dms_name" --query=ReplicationTasks[0].ReplicationTaskArn --output text --region "$aws_region"`

ri_arn=`aws dms describe-replication-tasks --filter Name=replication-task-id,Values=$dms_name --query=ReplicationTasks[0].ReplicationInstanceArn --region "$aws_region"`
target_arn=`aws dms describe-replication-tasks --filter Name=replication-task-id,Values=$dms_name --query=ReplicationTasks[0].TargetEndpointArn --region "$aws_region"`

ri_status=`aws dms describe-connections --filter Name=replication-instance-arn,Values=$ri_arn --query=Connections[0].Status --region "$aws_region"`
target_status=`aws dms describe-connections --filter Name=endpoint-arn,Values=$target_arn --query=Connections[0].Status --region "$aws_region"`

retry_cli () {
        local max_retry=100
        local counter=0
        local sleep_seconds=15 
        local status="$1"
        until [[ "${status}" =~ "success" ]]
        do
            echo ${status} $3
            status=`aws dms describe-connections --filter Name=$2,Values="$3" --query=Connections[0].Status --region "$4"`
            [[ counter -eq $max_retry ]] && echo "connection status of $3 failed!" && exit 1
            ((counter++))
            sleep $sleep_seconds
        done
        echo "connection for $3 OK!"
}

retry_cli "$ri_status" replication-instance-arn "$ri_arn" "$aws_region"
retry_cli "$target_status" endpoint-arn "$target_arn" "$aws_region"

echo startting dms
aws dms start-replication-task --replication-task-arn "$dms_arn" --start-replication-task-type resume-processing --region "$aws_region"
echo done
