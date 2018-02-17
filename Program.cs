using System;
using System.IO;
using Vestris.ResourceLib;

namespace ResourceExtractor
{
    class Program
    {
        static int Main(string[] args)
        {
            if (args.Length < 2)
            {
                ShowHelp();
                return 1;
            }

            var filename = args[1];

            if (!File.Exists(filename))
            {
                Console.WriteLine("The executable {0} does not exist", filename);
                return 1;
            }

            switch (args[0])
            {
                case "list":
                    List(filename);
                    return 0;
                case "extract":
                    if (args.Length < 4)
                    {
                        ShowHelp();
                        return 1;
                    }
                    Extract(filename, args[2], args[3]);
                    return 0;
                default:
                    Console.WriteLine("Unknown command");
                    return 1;
            }
        }

        private static void ShowHelp()
        {
            Console.WriteLine("ResourceExtractor list <executable>");
            Console.WriteLine("ResourceExtractor extract <executable> <id> <extract to file name>");
        }

        private static void Enumerate(string filename, Func<string, Resource, bool> visit)
        {
            using (var resources = new ResourceInfo())
            {
                resources.Load(filename);

                foreach (var resource in resources)
                {
                    var resourceId = string.Format("{0}/{1}/{2}", resource.Type.TypeName, resource.Name, resource.Language);

                    if (visit(resourceId, resource))
                    {
                        return;
                    }
                }
            }
        }

        private static void List(string filename)
        {
            Enumerate(filename, (resourceId, resource) =>
            {
                Console.WriteLine("{0}\t{1}", resourceId, resource.Size);
                return false;
            });
        }

        private static void Extract(string filename, string id, string destinationFilename)
        {
            Enumerate(filename, (resourceId, resource) =>
            {
                if (resourceId == id)
                {
                    File.WriteAllBytes(destinationFilename, resource.WriteAndGetBytes());
                    return true;
                }
                return false;
            });
        }
   }
}
