use core::starknet::ContractAddress;
// use core::starknet::storage::Map;

#[starknet::interface]
pub trait IInnov8Pulse<TContractState> {
    fn submit_project(
        ref self: TContractState,
        project_id: felt252,
        project_name: felt252,
        description: felt252,
        contributors: felt252,
        tags: felt252
    );
    fn get_project(self: @TContractState, project_id: felt252) -> Innov8Pulse::Project;
    fn track_contribution(
        ref self: TContractState,
        project_id: felt252,
        contributor: ContractAddress,
        contribution: felt252
    );
    fn provide_feedback(
        ref self: TContractState, project_id: felt252, feedback: felt252, mentor: ContractAddress
    );
    fn get_all_projects(self: @TContractState);
}

#[starknet::contract]
mod Innov8Pulse {
    use starknet::storage::StoragePathEntry;
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{Map, StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        projects: Map::<felt252, Project>,
        project_ids: Map::<u128, felt252>,
        contributions: Map::<felt252, Map<ContractAddress, felt252>>,
        feedbacks: Map::<felt252, Map<ContractAddress, felt252>>,
        total_projects: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct ProjectSubmitted {
        #[key]
        project_id: felt252,
        project_name: felt252,
        description: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ContributionTracked {
        #[key]
        project_id: felt252,
        contributor: ContractAddress,
        contribution: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct FeedbackProvided {
        #[key]
        project_id: felt252,
        mentor: ContractAddress,
        feedback: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct AllProjectsRetrieved {
        #[key]
        project_id: felt252,
        project_name: felt252,
        description: felt252,
        owner: ContractAddress,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Project {
        project_id: felt252,
        project_name: felt252,
        description: felt252,
        owner: ContractAddress,
        contributors: felt252,
        tags: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl Implnnov8Pulse of super::IInnov8Pulse<ContractState> {
        fn submit_project(
            ref self: ContractState,
            project_id: felt252,
            project_name: felt252,
            description: felt252,
            contributors: felt252,
            tags: felt252
        ) {
            let caller = get_caller_address();
        
            let project = Project {
                project_id: project_id,
                project_name: project_name,
                description: description,
                owner: caller,
                contributors: contributors,
                tags: tags,
            };
        
            self.projects.entry(project_id).write(project);
        
            let index = self.total_projects.read();
            self.project_ids.entry(index).write(project_id);
            self.total_projects.write(index + 1);
        
            ProjectSubmitted {
                project_id: project_id,
                project_name: project_name,
                description: description,
            };
        }

        fn get_project(self: @ContractState, project_id: felt252) -> Project {
            self.projects.entry(project_id).read()
        }

        fn track_contribution(
            ref self: ContractState,
            project_id: felt252,
            contributor: ContractAddress,
            contribution: felt252
        ) {
            let mut project_contributions = self.contributions.entry(project_id);
            project_contributions.entry(contributor).write(contribution);

            ContributionTracked {
                project_id: project_id,
                contributor: contributor,
                contribution: contribution,
            };
        }

        fn provide_feedback(
            ref self: ContractState, project_id: felt252, feedback: felt252, mentor: ContractAddress
        ) {
            let mut project_feedbacks = self.feedbacks.entry(project_id);
            project_feedbacks.entry(mentor).write(feedback);

            FeedbackProvided { 
                project_id: project_id, 
                mentor: mentor, 
                feedback: feedback, 
            };
        }

        fn get_all_projects(self: @ContractState) {
            let project_count = self.total_projects.read();

            for i in 0..project_count {
                let project_id = self.project_ids.entry(i).read();
                let _project = self.projects.entry(project_id).read();

                AllProjectsRetrieved {
                    project_id: _project.project_id,
                    project_name: _project.project_name,
                    description: _project.description,
                    owner: _project.owner,
                };
            }
        }
    }
}
