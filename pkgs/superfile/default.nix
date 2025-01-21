{ lib
, getByName'
}:
(getByName' "superfile").overrideAttrs {
  meta = {
    description = "Pretty fancy and modern terminal file manager";
    homepage = "https://superfile.netlify.app/";
    platforms = lib.platforms.all;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ spitulax ];
  };
}
