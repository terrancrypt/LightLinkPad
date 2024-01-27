import { NavLink } from "react-router-dom";
import { ProjectInfor } from "../projectInfor.type";

const ProjectTag: React.FC<ProjectInfor> = ({
  img,
  projectName,
  totalRaise,
  tag,
}) => {
  return (
    <div className="grid grid-cols-4 my-4 py-5 shadow font-medium text-sm border border-transparent hover:border hover:border-[#0072bc] hover:shadow-xl transition-all">
      <div className="flex items-center justify-center gap-2">
        <img className="w-[40px] h-[40px] rounded-full" src={img} alt="" />
        <span>{projectName}</span>
      </div>
      <span className="flex items-center justify-center">${totalRaise}</span>
      <div className="flex items-center justify-center ">
        <span
          className={`${
            tag === "Upcoming"
              ? "bg-yellow-500"
              : tag === "Live"
              ? "bg-green-600"
              : "bg-blue-600"
          } py-1 px-4 rounded-full text-white bg-opacity-90 flex items-center justify-center `}
        >
          {tag}
        </span>
      </div>
      <div className="flex items-center justify-center">
        <NavLink
          className="py-1 px-4 rounded-full bg-[#0072bc] text-white hover:bg-opacity-90 transition-all hover:scale-105"
          to={""}
        >
          Detail
        </NavLink>
      </div>
    </div>
  );
};

export default ProjectTag;
