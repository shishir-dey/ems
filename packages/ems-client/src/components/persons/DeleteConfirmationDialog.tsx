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
import { deletePerson } from "../../services/personService";

interface DeleteConfirmationDialogProps {
  isOpen: boolean;
  onClose: () => void;
  personId: string;
  personName?: string;
  onDeleted: () => void;
}

const DeleteConfirmationDialog: React.FC<DeleteConfirmationDialogProps> = ({
  isOpen,
  onClose,
  personId,
  personName,
  onDeleted,
}) => {
  const handleDelete = async () => {
    try {
      await deletePerson(personId);
      onDeleted();
    } catch (error) {
      console.error("Error deleting person:", error);
    }
    onClose();
  };

  return (
    <AlertDialog open={isOpen} onOpenChange={onClose}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete Person</AlertDialogTitle>
          <AlertDialogDescription>
            Are you sure you want to delete{" "}
            {personName ? `"${personName}"` : "this person"}? This action cannot
            be undone.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel onClick={onClose}>Cancel</AlertDialogCancel>
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
