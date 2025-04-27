class Server
{
    String ip;
    int port;
    ArrayList<Integer> cubeIds;

    Server(String ip, int port, int[] cubeIds)
    {
        this.ip = ip;
        this.port = port;
        this.cubeIds = new ArrayList<Integer>();
        for (int cubeId : cubeIds)
        {
            this.cubeIds.add(cubeId);
        }
    }

    boolean managesCube(int cubeId)
    {
        return cubeIds.contains(cubeId);
    }

    NetAddress getAddress()
    {
        return new NetAddress(ip, port);
    }
}
