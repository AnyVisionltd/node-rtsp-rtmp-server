import argparse
import consul
import os


def post_env_to_consul(exclude_file_path, consul_host, consul_port):
    exclude_list = list(env.strip() for env in open(exclude_file_path, "r").readlines())
    local_consul = consul.Consul(host=consul_host, port=consul_port)
    consul_prefix = exclude_file_path.split("/")[-1].split("_")[0]
    for env_key in os.environ.keys():
        if env_key not in exclude_list:
            env_value = os.environ.get(env_key, "None")
            local_consul.kv.put(key="{}/{}".format(consul_prefix, env_key.strip("/")), value=env_value, cas=0)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--exclude_file', default="api-env_exclude.txt", type=str, required=True, help="json file to parse")
    parser.add_argument('-c', '--consul_db_host', type=str, required=False, default="consul.tls.ai",
                        help='consul host name')
    parser.add_argument('-p', '--consul_db_port', type=int, required=False, default=8500, help='consul port')

    args = parser.parse_args()

    file_path = args.exclude_file
    if not os.path.exists(file_path):
        raise IOError("No such file or dir {}".format(file_path))
    post_env_to_consul(file_path, args.consul_db_host, args.consul_db_port)
