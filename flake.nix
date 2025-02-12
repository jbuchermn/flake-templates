{
  description = "Project templates";

  outputs =
    { ... }:
    {
      templates = {
        clash = {
          path = ./clash;
          description = "Clash starter project";
        };
      };
    };
}
