import React from "react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "../ui/alert-dialog";
import { deleteJob } from "../../services/jobService.ts";

interface DeleteConfirmationDialogProps {
  isOpen: boolean;
  onClose: () => void;
  jobId: string;
  jobNumber?: string;
  onDeleted: () => void;
}

const DeleteConfirmationDialog: React.FC<DeleteConfirmationDialogProps> = ({
  isOpen,
  onClose,
  jobId,
  jobNumber,
  onDeleted,
}) => {
  const handleDelete = async () => {
    try {
      await deleteJob(jobId);
      onDeleted();
    } catch (error) {
      console.error("Error deleting job:", error);
    } finally {
      onClose();
    }
  };

  return (
    <AlertDialog open={isOpen} onOpenChange={onClose}>
      <AlertDialogContent
        className="bg-white dark:bg-slate-900 !bg-opacity-100 border-2 border-gray-200 shadow-lg rounded-lg"
        style={{ backgroundColor: "white", opacity: 1 }}
      >
        <AlertDialogHeader>
          <AlertDialogTitle>Confirm Deletion</AlertDialogTitle>
          <AlertDialogDescription>
            Are you sure you want to delete job {jobNumber || jobId}? This
            action cannot be undone.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleDelete}
            className="bg-red-600 hover:bg-red-700"
          >
            Delete
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
};

export default DeleteConfirmationDialog;
