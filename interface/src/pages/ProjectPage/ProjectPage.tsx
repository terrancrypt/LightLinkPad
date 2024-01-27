import { Fragment, useEffect } from "react";
import ProjectTag from "./components/ProjectTag";
import projectData from "./projectData";
import { ProjectInfor } from "./projectInfor.type";

export const ProjectPage = () => {
  const renderProjects = () =>
    projectData?.map((project: ProjectInfor, index) => (
      <Fragment key={index}>
        <ProjectTag
          img={project.img}
          projectName={project.projectName}
          totalRaise={project.totalRaise}
          tag={project.tag}
        />
      </Fragment>
    ));

  return (
    <div className="container mx-auto px-10 py-2">
      <div className="py-8">
        <h2 className="font-medium text-xl ml-8 text-center">
          Featured IDO that hosted on Light Pad
        </h2>
        <div>
          <div className="w-full text-center mt-10 ">
            <div className="grid grid-cols-4 text-[#64748b] font-medium text-sm">
              <span>Project Name</span>
              <span>Total Raise</span>
              <span>State</span>
              <span></span>
            </div>
            {renderProjects()}
          </div>
        </div>
      </div>
    </div>
  );
};
